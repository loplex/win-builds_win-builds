include ../Makefile.data

export LIBRARY_PATH:=$(PREFIX)/lib:$(LIBRARY_PATH)
export C_INCLUDE_PATH:=$(PREFIX)/include:$(C_INCLUDE_PATH)

NEEDS = $(shell (export PATH=$(PATH); $(1) 2>/dev/null | tr '\n' ' ' | grep '$(2)' >/dev/null 2>/dev/null) || echo '$(3)')
NEEDS_GNU = $(call NEEDS,$(1) --version,$(2).*Free Software Foundation,$(3))
NEEDS_HEADER = $(call NEEDS,echo '\#include <$(1)>' | cc - -E -I$(PREFIX)/include,.,$(2))

NEEDS_XZ := $(call NEEDS,xz --version,XZ Utils,xz)
NEEDS_LIBLZMA := $(call NEEDS_HEADER,lzma.h,liblzma)
NEEDS_COREUTILS := $(call NEEDS_GNU,cp,,coreutils)
NEEDS_PATCH := $(call NEEDS_GNU,patch,,patch)
NEEDS_TAR := $(call NEEDS_GNU,tar,,tar)
NEEDS_MAKE := $(call NEEDS_GNU,make,4\.[^0]$,make)
NEEDS_SED := $(call NEEDS_GNU,sed,,sed)
NEEDS_FINDUTILS := $(call NEEDS_GNU,find,,findutils)
NEEDS_BASH := bash
NEEDS_LIBARCHIVE := $(call NEEDS_HEADER,archive.h,libarchive)
NEEDS_BSDTAR := $(call NEEDS,bsdtar --version,libarchive,bsdtar)
# TODO: ocaml and findlib are a bit annoying to skip because the system ones
# have strong opinions on where installed files should go and we don't want to
# require root.
NEEDS_OCAML := ocaml
NEEDS_FINDLIB := findlib

PATCHES := $(shell pwd)/patches

DOWNLOAD_AND_EXTRACT = \
	rm -rf "$(1)" \
	&& mkdir -p tarballs \
	&& if ! [ -e "tarballs/$(1).$(2)" ]; then \
		(cd tarballs && curl "$(YYPKG_FILES)/$(1).$(2)" > "$(1).$(2)" || rm -f "$(1).$(2)") \
	fi \
	&& (case $(2) in \
	  "tar.gz"|"tgz") tar xzf "tarballs/$(1).$(2)";; \
	  "tar.bz2"|"tbz2") tar xjf "tarballs/$(1).$(2)";; \
	  "tar.xz"|"txz") xz -d < "tarballs/$(1).$(2)" | tar xf - ;; \
	esac)

BUILD_AUTOTOOLS = \
	cd $(1)-$(2) \
	&& ./configure --prefix=$(PREFIX) $(3) \
	&& $(MAKE) \
	&& $(MAKE) install

BUILD_OASIS = \
	cd $(1)-$(2) \
	&& ocaml setup.ml -configure --prefix $(PREFIX) $(3) \
	&& ocaml setup.ml -build -j 4 \
	&& ocaml setup.ml -install

P = patch --verbose -p1 < "$(PATCHES)/$(1).patch"

default: summary
	$(MAKE) -C . all

summary:
	f() { echo "[$$(echo $$1 | sed -e "s/$$2/X/" -e 's/^$$/ /')] $$2"; }; \
	echo "Dependencies needed (largest ones):"; \
	f "$(NEEDS_COREUTILS)" "coreutils"; \
	f "$(NEEDS_MAKE)" "make"; \
	f "$(NEEDS_SED)" "sed"; \
	f "$(NEEDS_FINDUTILS)" "findutils"; \
	f "$(NEEDS_PATCH)" "patch"; \
	f "$(NEEDS_TAR)" "tar"; \
	f "$(NEEDS_BASH)" "bash"; \
	f "$(NEEDS_XZ)" "xz"; \
	f "$(NEEDS_LIBLZMA)" "liblzma"; \
	f "$(NEEDS_LIBARCHIVE)" "libarchive"; \
	f "$(NEEDS_BSDTAR)" "bsdtar"; \
	f "$(NEEDS_OCAML)" "ocaml"; \
	f "$(NEEDS_FINDLIB)" "findlib"

all: $(NEEDS_COREUTILS) $(NEEDS_MAKE) $(NEEDS_SED) $(NEEDS_FINDUTILS) $(NEEDS_PATCH) $(NEEDS_TAR) $(NEEDS_BASH) $(NEEDS_LIBARCHIVE) yypkg

xz liblzma:
	$(call DOWNLOAD_AND_EXTRACT,xz-$(XZ_VERSION),tar.bz2)
	$(call BUILD_AUTOTOOLS,xz,$(XZ_VERSION),)

m4: $(NEEDS_XZ)
	$(call DOWNLOAD_AND_EXTRACT,m4-$(M4_VERSION),tar.xz)
	$(call BUILD_AUTOTOOLS,m4,$(M4_VERSION),)

coreutils: $(NEEDS_XZ)
	$(call DOWNLOAD_AND_EXTRACT,coreutils-$(COREUTILS_VERSION),tar.xz)
	export FORCE_UNSAFE_CONFIGURE=1; \
	$(call BUILD_AUTOTOOLS,coreutils,$(COREUTILS_VERSION),--without-gmp)

make:
	$(call DOWNLOAD_AND_EXTRACT,make-$(MAKE_VERSION),tar.bz2)
	$(call BUILD_AUTOTOOLS,make,$(MAKE_VERSION),)

findutils: $(NEEDS_XZ)
	$(call DOWNLOAD_AND_EXTRACT,findutils-$(FINDUTILS_VERSION),tar.xz)
	$(call BUILD_AUTOTOOLS,findutils,$(FINDUTILS_VERSION),)

sed: $(NEEDS_XZ)
	$(call DOWNLOAD_AND_EXTRACT,sed-$(SED_VERSION),tar.xz)
	$(call BUILD_AUTOTOOLS,sed,$(SED_VERSION),)

bash:
	$(call DOWNLOAD_AND_EXTRACT,bash-$(BASH_VERSION),tar.gz)
	cd "bash-$(BASH_VERSION)" && $(call P,bash/nfd_lte_nbuffers)
	$(call BUILD_AUTOTOOLS,bash,$(BASH_VERSION),)

tar: $(NEEDS_XZ)
	$(call DOWNLOAD_AND_EXTRACT,tar-$(TAR_VERSION),tar.xz)
	export FORCE_UNSAFE_CONFIGURE=1; $(call BUILD_AUTOTOOLS,tar,$(TAR_VERSION),)

patch:
	$(call DOWNLOAD_AND_EXTRACT,patch-$(PATCH_VERSION),tar.bz2)
	$(call BUILD_AUTOTOOLS,patch,$(PATCH_VERSION),)

libarchive bsdtar: $(NEEDS_LIBLZMA)
	$(call DOWNLOAD_AND_EXTRACT,libarchive-$(LIBARCHIVE_VERSION),tar.gz)
	$(call BUILD_AUTOTOOLS,libarchive,$(LIBARCHIVE_VERSION),--disable-bsdcpio --without-zlib --without-xml2 --without-expat --without-openssl --without-nettle --without-lzo2 --without-lzmadec --without-bz2lib --without-zlib)

ocaml: $(NEEDS_MAKE) $(NEEDS_XZ)
	$(call DOWNLOAD_AND_EXTRACT,ocaml-$(OCAML_VERSION),tar.xz)
	(cd ocaml-$(OCAML_VERSION) \
		&& sed -i -e 's/_execvpe proc args/\0 env/' -e 's/let execvpe proc args/\0 env/' otherlibs/threads/unix.ml \
		&& $(call P,ocaml/ocaml_execvpe) \
		&& ./configure -no-debugger -prefix $(PREFIX) \
		&& $(MAKE) -j1 world.opt \
		&& $(MAKE) -j1 install)

findlib: $(NEEDS_OCAML)
	$(call DOWNLOAD_AND_EXTRACT,findlib-$(FINDLIB_VERSION),tar.gz)
	(cd findlib-$(FINDLIB_VERSION) \
		&& ./configure -no-camlp4 \
		&& $(MAKE) -j1 \
		&& $(MAKE) install)

libocaml: $(NEEDS_OCAML) $(NEEDS_FINDLIB) $(NEEDS_XZ)
	for s in exception option lexing plus ipv4_address ipv6_address uri http; do \
		$(call DOWNLOAD_AND_EXTRACT,libocaml_$${s}.$(LIBOCAML_VERSION),tar.xz) \
		&& sed -i '/-w @a-4-6-7-9-23-26-27-29-41/ s/@//' \
			libocaml_$${s}.$(LIBOCAML_VERSION)/lib/libocaml/make/GNUmakefile; \
	done
	cp post-ocamllex libocaml_lexing.$(LIBOCAML_VERSION)/src
	for s in exception option lexing plus ipv4_address ipv6_address uri http; do \
		(cd libocaml_$${s}.$(LIBOCAML_VERSION) && $(MAKE) && $(MAKE) install); \
	done

ocaml-fileutils: $(NEEDS_OCAML) $(NEEDS_FINDLIB)
	ocamlfind remove fileutils
	$(call DOWNLOAD_AND_EXTRACT,ocaml-fileutils-$(FILEUTILS_VERSION),tar.gz)
	cd ocaml-fileutils-$(FILEUTILS_VERSION) \
	&& $(call P,fileutils/0001-FileUtil-replace-stat.is_link-boolean-with-a-Link-va) \
	&& $(call P,fileutils/0002-FileUtil-symlinks-patch-2)
	$(call BUILD_OASIS,ocaml-fileutils,$(FILEUTILS_VERSION),)

ocaml-archive: $(NEEDS_OCAML) $(NEEDS_FINDLIB) $(NEEDS_LIBARCHIVE) $(NEEDS_SED)
	ocamlfind remove archive
	$(call DOWNLOAD_AND_EXTRACT,ocaml-archive-$(ARCHIVE_VERSION),tar.gz)
	cd ocaml-archive-$(ARCHIVE_VERSION) \
	&& $(call P,archive/0001-_oasis-make-it-possible-to-not-build-tests-docs-and-) \
	&& $(call P,archive/0002-Bind-extract-set_pathname-and-read_open_memory-strin) \
	&& $(call P,archive/0003-stubs-bind-archive_entry_-set_-pathname-through-a-ma) \
	&& $(call P,archive/0004-Bind-archive_entry_-set_-hard-sym-link-and-archive_e) \
	&& $(call P,archive/0001-stubs-ARCHIVE_EXTRACT_-MAC_METADATA-NO_HFS_COMPRESSI) \
	&& sed -i 's/malloc\.h/stdlib\.h/' src/Archive_stub.c
	$(call BUILD_OASIS,ocaml-archive,$(ARCHIVE_VERSION),--disable-archivelwt --disable-tests --disable-docs)

cryptokit: $(NEEDS_OCAML) $(NEEDS_FINDLIB)
	ocamlfind remove cryptokit
	$(call DOWNLOAD_AND_EXTRACT,cryptokit-$(CRYPTOKIT_VERSION),tar.gz)
	$(call BUILD_OASIS,cryptokit,$(CRYPTOKIT_VERSION),)

yypkg: $(NEEDS_OCAML) $(NEEDS_FINDLIB) $(NEEDS_BSDTAR) libocaml ocaml-fileutils ocaml-archive cryptokit $(NEEDS_XZ)
	$(call DOWNLOAD_AND_EXTRACT,yypkg-$(YYPKG_VERSION),tar.gz)
	cd yypkg-$(YYPKG_VERSION) && $(MAKE) yypkg-no-gui
	cp -L yypkg-$(YYPKG_VERSION)/src/yypkg.native $(PREFIX)/bin/yypkg

ocaml-efl:
	ocamlfind remove efl
	$(call DOWNLOAD_AND_EXTRACT,ocaml-efl-$(OCAML_EFL_VERSION),tar.gz)
	$(call BUILD_AUTOTOOLS,ocaml-efl,$(OCAML_EFL_VERSION),OCAMLFIND_DESTDIR="$$(ocamlfind printconf destdir)")

.PHONY: coreutils make ocaml findlib sed findutils yypkg

include Makefile.data

default: build

build_real:
	ocaml str.cma build/amalgation.ml > build/amalgated.ml \
	&& LANG="C" NUMJOBS="$(NUMJOBS)" BUILD_TRIPLET="$(BUILD_TRIPLET)" TAR_VERBOSE="$(TAR_VERBOSE)" \
	  ocaml unix.cma str.cma -I +threads threads.cma \
		build/amalgated.ml $(VERSION)

ifneq ($(WITH_LXC),)

YYBASEPATH = /opt
LXC_EXECUTE = lxc-execute -f $(shell pwd)/lxc.conf -n win-builds-$(VERSION) -s lxc.mount=$(shell pwd)/lxc_mount --

build:
	: > lxc_mount
	P="$(shell pwd)/opt"; \
	for f in native_toolchain {cross_toolchain,windows}_{32,64}; do \
	  mkdir -p "$${P}/$${f}"; \
	  echo "$${P}/$${f} /opt/$${f} none bind,create=dir 0 0" >> lxc_mount; \
	done

else

YYBASEPATH ?= $(shell pwd)/opt
LXC_EXECUTE =

build:

endif
	$(LXC_EXECUTE) $$(which $$(basename $$(echo "$(MAKE)" | cut -f1 -d' '))) \
		build_real \
		NATIVE_TOOLCHAIN="$(NATIVE_TOOLCHAIN)" \
		CROSS_TOOLCHAIN_32="$(CROSS_TOOLCHAIN),$(CROSS_TOOLCHAIN_32)" \
		CROSS_TOOLCHAIN_64="$(CROSS_TOOLCHAIN),$(CROSS_TOOLCHAIN_64)" \
		WINDOWS_32="$(WINDOWS),$(WINDOWS_32)" \
		WINDOWS_64="$(WINDOWS),$(WINDOWS_64)" \
		WINDOWS_MINISTAT="$(WINDOWS_MINISTAT)" \
		YYBASEPATH="$(YYBASEPATH)" \
		WIN_BUILDS_SOURCES="$(WIN_BUILDS_SOURCES)" \
		PATH="$(PATH)" \
		LD_LIBRARY_PATH="$(LD_LIBRARY_PATH)" \
		PREFIX="$(PREFIX)"

deps:
	$(MAKE) -C deps PREFIX="$(PREFIX)" PATH="$(PATH)" LD_LIBRARY_PATH="$(LD_LIBRARY_PATH)"

tarballs-upload:
	set -o pipefail; \
	LOGLEVEL=dbg DRYRUN=1 $(MAKE) WINDOWS=all WINDOWS_MINISTAT=yypkg 2>&1 \
	  | sed -nu -e 's;^ [^ ]\+ -> source=\(.\+/.\+/.\+\);\1; p' -e '/^File\>/ w /dev/stderr' \
	  | tee file_list
	rsync -avP --chmod=D755,F644 --delete-after --files-from=file_list . $(WEB)/$(VERSION)/tarballs/$$dir/
	rm file_list

installer:
	rm -rf installer
	mkdir -p installer
	export YYPREFIX="$$(pwd)/installer"; \
	yypkg --init; \
	rm -f installer/bin/yypkg; \
	cd $(VERSION)/packages/windows_32; \
	for p in dbus*--* fontconfig*--* harfbuzz*--* c-ares* winpthreads* gcc* zlib* win-iconv* gettext* lua* libjpeg* libpng* expat* freetype* fribidi* efl* elementary* dejavu-fonts-ttf* yypkg-$(YYPKG_VERSION)-*; do \
	  yypkg --install "$${p}"; \
	done
	cd installer; \
	find share/fonts/TTF \( -name '*.ttf' \! -name DejaVuSans.ttf \! -name DejaVuSans-Bold.ttf \) -exec rm -rf {} +; \
	find bin -name '*.exe' \! -name 'yypkg*.exe' -exec rm -rf {} +; \
	rm -rf {doc,i686-w64-mingw32,include,info,libexec,man,var}; \
	rm -rf etc/yypkg.d; \
	rm -rf bin/libecore_{audio,avahi,ipc}-1.dll bin/libeolian-1.dll; \
	rm -rf bin/libgomp-1.dll bin/lib{quadmath,ssp}-0.dll; \
	rm -rf bin/{edje_recc,eina-bench-cmp,gettext.sh,vieet} bin/*-config; \
	rm -rf lib/evas/modules/{engines/software_ddraw,loaders,savers}; \
	rm -rf lib/{ethumb,elementary,gcc,cmake,cpp.exe,*.def,pkgconfig,python2.7,efreet,ethumb_client}; \
	find lib \( -name '*.dll.a' -o -name '*.a' \) -exec rm -rf {} +; \
	rm -rf lib/libgomp.spec lib/dbus-1; \
	rm -rf share/{elementary/images,eolian,applications,icons,mime,gdb,eo,dbus}; \
	rm -rf share/{locale,elementary/objects,curl,gettext,aclocal}
	find . -type l -exec rm {} +
	tar cv -C installer --exclude='bin/yypkg_wrapper.exe' . \
	  | xz -8vv > win-builds-$(VERSION).tar.xz
	(cat installer/bin/yypkg_wrapper.exe; \
	  cat win-builds-$(VERSION).tar.xz; \
	  ./yypkg/src/wrapper.native $$(stat --printf='%s' win-builds-$(VERSION).tar.xz)) \
	  > win-builds-$(VERSION).exe

installer-upload: installer
	rsync -avP win-builds-$(VERSION).exe $(WEB)/$(VERSION)/

release-upload:
	rsync -avzP \
	  --exclude='memo_pkg' \
	  --delete-after \
	  --no-perms \
	  $(VERSION)/{logs,packages} \
	  $(WEB)/$(VERSION)/


.PHONY: build deps installer build_real default

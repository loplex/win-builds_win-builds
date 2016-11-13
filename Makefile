include Makefile.data

default: build

build_real:
	@ocaml str.cma build/amalgation.ml > build/amalgated.ml
	@echo "BUILD LOCATION   =   \"$(YYBASEPATH)\""
	@echo "NUMJOBS          =   \"$(NUMJOBS)\""
	@echo "TAR_VERBOSE      =   \"$(TAR_VERBOSE)\""
	@echo "BUILD_TRIPLET    =   \"$(BUILD_TRIPLET)\""
	@LC_ALL="C" NUMJOBS="$(NUMJOBS)" BUILD_TRIPLET="$(BUILD_TRIPLET)" TAR_VERBOSE="$(TAR_VERBOSE)" ocaml unix.cma str.cma -I +threads threads.cma build/amalgated.ml $(VERSION)

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
	@$(LXC_EXECUTE) $$(which $$(basename $$(echo "$(MAKE)" | cut -f1 -d' '))) \
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
	@BRANCH_L="$$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)"; \
	BRANCH_R="$$(git rev-parse --symbolic-full-name --abbrev-ref HEAD@{u})"; \
	REMOTE="$${BRANCH_R%%/*}"; \
	REMOTE_URL="$$(git config "remote.$${REMOTE}.url")"; \
	for repo in slackware slackbuilds.org; do \
	  if ! [ -d "$${repo}" ] && ! [ -L "$${repo}" ]; then \
	    git clone --no-checkout "$${REMOTE_URL%/win-builds.git}/$${repo}.git"; \
	    git -C "$${repo}" checkout -b "$${BRANCH_L}" "$${BRANCH_R}"; \
	  fi; \
	done
	$(MAKE) -C deps

tarballs-upload:
	set -o pipefail; \
	LOGLEVEL=dbg DRYRUN=1 $(MAKE) WINDOWS=all WINDOWS_MINISTAT=yypkg 2>&1 \
	  | sed -nu -e 's;^ [^ ]\+ -> source=\(.\+/.\+/.\+\);\1; p' -e '/^File\>/ w /dev/stderr' \
	  | tee file_list
	rsync -avP --chmod=D755,F644 --delete-after --files-from=file_list . $(WEB)/$(VERSION)/tarballs/$$dir/
	rm file_list

release-upload:
	rsync -avzP \
	  --exclude='memo_pkg' \
	  --delete-after \
	  --no-perms \
	  $(VERSION)/{logs,packages} \
	  $(WEB)/$(VERSION)/


.PHONY: build deps installer build_real default

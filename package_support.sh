#!/bin/sh

set -eux

SRCDIR="${1}"
PACKAGE="${2}"
VARIANT="${3}"
VERSION="${4}"
BUILD="${5}"
DEVSHELL="${6}"

export VERSION BUILD

yyextract() {
  local CWD="${1:?'The current working directory must be provided.'}"
  local BASE="${2:?"The archive's base name must be provided."}"
  find "${CWD}" -maxdepth 1 -name "${BASE}.*" -a \( -name '*.tar.[gx]z' -o -name '*.t[bgx]z' -o -name '*.tar.bz2' -o -name '*.tbz2' \) -exec tar xf${TAR_VERBOSE} {} +
}

yycflags() {
  local dbg
  local hardening
  local optimization

  case "${YYOPTIMIZATION}" in
    *) optimization='-O2' ;;
  esac

  case "${YYDEBUG}" in
    3) dbg='-ggdb3' ;;
    2) dbg='-ggdb2' ;;
    1 | *) dbg='-ggdb' ;;
    0) dbg='-ggdb0' ;;
  esac

  case "${YYHARDENING}" in
    *) hardening='' ;;
  esac

  echo ${optimization} ${dbg} ${hardening}
}

yycxxflags() {
  yycflags "$@"
}

yyldflags() {
  local triplet="${1:-"${HOST_TRIPLET}"}"

  local library_path=''
  local hardening=''
  local high_entropy_va=''

  case "${YYDEFAULTLIBRARYPATH}" in
    no) library_path='' ;;
    *)
      case "${HOST_PREFIX}" in
        "${TARGET_PREFIX}") library_path="-L/${PREFIX}/lib${LIBDIRSUFFIX}" ;;
        *) library_path='' ;;
      esac
  esac

  case "${triplet}" in
    x86_64-w64-mingw32)
      dynamicbase=',--dynamicbase'
      nxcompat=',--nxcompat'
      high_entropy_va=',--high-entropy-va'
      ;;
    i?86-w64-mingw32)
      dynamicbase=',--dynamicbase'
      nxcompat=',--nxcompat'
      high_entropy_va=''
      ;;
    *)
      dynamicbase=''
      nxcompat=''
      high_entropy_va=''
      ;;
  esac
  case "${YYHARDENING}" in
    no) hardening='' ;;
    *) hardening="${dynamicbase}${nxcompat}${high_entropy_va}" ;;
  esac

  echo ${library_path} ${hardening:+"-Wl${hardening}"}
}

yystrip() {
  # HOST_EXE_FORMAT ?
  (cd "${PKG}" && \
    find . -type f -size +4k -printf '%P\n' -exec file {} + \
    | awk -F':' "/${HOST_EXE_FORMAT}.*(executable|shared object)/"' {print $1}' \
    | while read file; do \
        DEBUG="${PKG}/${PREFIX}/lib${LIBDIRSUFFIX}/debug/${file}.debug"
        mkdir -p "${DEBUG%/*}"
        objcopy --only-keep-debug "${file}" "${DEBUG}"
        objcopy --strip-debug "${file}"
        objcopy --add-gnu-debuglink="${DEBUG}" "${file}"
      done
  )
}

yymakepkg() {
  local PKGNAM="${1}"
  local SUB="${2}"
  local TARGET_TRIPLET="${3}"
  shift 3

  local DESCR="$(sed -n 's;^[^:]\\+: ;; p' "${CWD}/slack-desc" | sed -e 's;";\\\\";g' -e 's;/;\\/;g' | tr '\\n' ' ')"

  local shellopts="$(set +o)"
  set -u

  yypkg --makepkg --template 'yes' | sed \
    -e "s/%{PKG}/${PKGNAM}${SUB:+-${SUB}}/" \
    -e "s/%{HST}/${HOST_TRIPLET}/" \
    -e "s/some %{TGT}/${TARGET_TRIPLET}/" \
    -e "s/%{VER} 0/${VERSION} ${BUILD}/" \
    -e "s/%{PACKAGER_MAIL}/${PACKAGER_MAIL}/" \
    -e "s/%{PACKAGER}/\"${PACKAGER}\"/" \
    -e "s/%{DESCR}/\"${DESCR:-"No description"}\"/" \
    -e "s/(some_predicate some_value)/${SUB:+(${SUB} "yes")}/" \
    | yypkg --makepkg --output ${YYOUTPUT} --script - \
        --directory "${PKG}/${PREFIX}" \
        --tar-args -- "$@"

  eval "${shellopts}"
}

yymakepkg_split() {
  local PKGNAM="${1:?'The package name must be provided.'}"
  local TARGET_TRIPLET="${2}"

  local TAR_DIR="${PREFIX##*/}"

  yystrip

  yymakepkg "${PKGNAM}" "" "${TARGET_TRIPLET}" \
    -C "${PKG}/${PREFIX}/.." --exclude "lib${LIBDIRSUFFIX}/debug" "${TAR_DIR}"
  yymakepkg "${PKGNAM}" "dbg" "${TARGET_TRIPLET}" \
    -C "${PKG}/${PREFIX}/.." "${TAR_DIR}/lib${LIBDIRSUFFIX}/debug"

  wait
}

export -f \
  yyextract yystrip yymakepkg yymakepkg_split \
  yycflags yycxxflags yyldflags

export PREFIX="$(echo "${YYPREFIX}" | sed 's;^/;;')"

# Unfortunately, some bash versions have a bug for which no fixed version is
# currently released, even less deployed. Moreover, autoconf will try to
# re-exec the configure script with a "proper" shell as early as possible and
# prefers a bash from /bin or /usr/bin to one from $PATH; CONFIG_SHELL forces
# the use of our newly-built bash.
export CONFIG_SHELL="$(which bash)"

if ! chown root:root / 2>/dev/null; then chown() { : ; }; export -f chown; fi

cd "${SRCDIR}"

CONFIG="config${VARIANT:+-"${VARIANT}"}"
if [ -e "${CONFIG}" ]; then . "./${CONFIG}"; fi

if [ x"${DEVSHELL}" = x"true" ]; then
  exec bash --norc -i
else
  exec bash -x "${PACKAGE}.SlackBuild"
fi

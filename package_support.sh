#!/bin/sh

set -eux

SRCDIR="${1}"
PACKAGE="${2}"
VARIANT="${3}"
VERSION="${4}"
BUILD="${5}"
DEVSHELL="${6}"

export VERSION BUILD

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

yyasflags() {
  local dbg

  case "${YYDEBUG}" in
    0) dbg='' ;;
    *) dbg='-g' ;;
  esac

  echo ${dbg}
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

export -f yycflags yycxxflags yyasflags yyldflags

export PREFIX="$(echo "${YYPREFIX}" | sed 's;^/;;')"
export PATH="${WIN_BUILDS_SOURCES}/package_support:${PATH}"

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

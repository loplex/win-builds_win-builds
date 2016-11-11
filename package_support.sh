#!/bin/sh

set -eux

SRCDIR="${1}"
PACKAGE="${2}"
VARIANT="${3}"
VERSION="${4}"
BUILD="${5}"
DEVSHELL="${6}"

export VERSION BUILD

export PREFIX="$(echo "${YYPREFIX}" | sed 's;^/;;')"
export PATH="${WIN_BUILDS_SOURCES}/package_support:${PATH}"

# Unfortunately, some bash versions have a bug for which no fixed version is
# currently released, even less deployed. Moreover, autoconf will try to
# re-exec the configure script with a "proper" shell as early as possible and
# prefers a bash from /bin or /usr/bin to one from $PATH; CONFIG_SHELL forces
# the use of our newly-built bash.
export CONFIG_SHELL="$(which bash)"

# Try to chown / to the owner and group of /
# This is a no-op but should let us find out whether we're running as root and
# can chown arbitrary files or not
if ! chown root:root --reference=/ / 2>/dev/null; then
  chown() { : ; }
  export -f chown
fi

export MAKEFLAGS="${NUMJOBS}"

cd "${SRCDIR}"

CONFIG="config${VARIANT:+-"${VARIANT}"}"
if [ -e "${CONFIG}" ]; then . "./${CONFIG}"; fi

if [ x"${DEVSHELL}" = x"true" ]; then
  exec bash --norc -i
else
  exec bash -x "${PACKAGE}.SlackBuild"
fi

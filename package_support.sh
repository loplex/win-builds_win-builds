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
  local CWD="${1}"
  local BASE="${2}"
  find "${CWD}" -maxdepth 1 -name "${BASE}.*" -a \( -name '*.tar.[gx]z' -o -name '*.t[bgx]z' -o -name '*.tar.bz2' -o -name '*.tbz2' \) -exec tar xf${TAR_VERBOSE} {} +
}

yystrip() {
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
    -e "s/%{PACKAGER_MAIL}/adrien@notk.org/" \
    -e "s/%{PACKAGER}/\"Adrien Nader\"/" \
    -e "s/%{DESCR}/\"${DESCR:-"No description"}\"/" \
    -e "s/(some_predicate some_value)/${SUB:+(${SUB} "yes")}/" \
    | yypkg --makepkg --output ${YYOUTPUT} --script - \
        --tar-args -- -C "${PKG}" "$@"

  eval "${shellopts}"
}

export -f yyextract yystrip yymakepkg

export PREFIX="$(echo "${YYPREFIX}" | sed 's;^/;;')"

if ! chown root:root / 2>/dev/null; then chown() { : ; }; export -f chown; fi

cd "${SRCDIR}"

CONFIG="config${VARIANT:+-"${VARIANT}"}"
if [ -e "${CONFIG}" ]; then . "./${CONFIG}"; fi

if [ x"${DEVSHELL}" = x"true" ]; then
  exec bash --norc -i
else
  exec bash -x "${PACKAGE}.SlackBuild"
fi

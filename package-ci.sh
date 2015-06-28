#!/bin/sh -eux

get_versions() {
  find next/packages/cross_toolchain_32/ \
    -name 'mingw-w64-*.txz' \! -name '*--1*' \
    -exec ./win-builds/deps/prefix/bin/yypkg \
      --package --script --metadata --version {} + \
    | cut -f '3' -d ':' \
    | tr -d '"' \
    | sort
}

PRE="$(get_versions)"

make -C win-builds CROSS_TOOLCHAIN=mingw-w64:full-git

POST="$(get_versions)"

if [ x"${PRE}" != x"${POST}" ]; then
  make -C win-builds WINDOWS=all
fi

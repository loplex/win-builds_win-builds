open Sources

module Version = struct
  let mingw_w64 = "v3.3.0"
  let gcc = "4.8.3"
  let binutils = "2.24"

  let efl = "1.11.2"
  let elementary = "1.11.2"

  let autoconf = "2.69"
  let automake = "1.14.1"
  let libtool = "2.4.4"
  let gettext = "0.18.3.1"
end

module Source = struct
  let mingw_w64 =
    Tarball ("mingw-w64-${VERSION}.tar.bz2", "d31eac960d42e791970697eae5724e529c81dcd6")
  let gcc =
    Tarball ("gcc-${VERSION}.tar.xz", "f2f894d6652f697fede264c16c028746e9ee6243")
  let binutils =
    Tarball ("binutils-${VERSION}.tar.gz", "1b2bc33003f4997d38fadaa276c1f0321329ec56")

  let efl =
    Tarball ("${PACKAGE}-${VERSION}.tar.xz", "81007abb130e087d01101d082661ada0a8879568")
  let elementary =
    Tarball ("${PACKAGE}-${VERSION}.tar.xz", "d756b9c4763beebfbf494b9d2ee42cc2828dd4d8")

  let efl_git = Git.(T {
    tarball = "${PACKAGE}-${VERSION}.tar.gz";
    dir = "efl";
    prefix = "${PACKAGE}-${VERSION}";
    obj = Some "origin/master";
    uri = Some "http://git.enlightenment.org/core/efl.git";
    remote = Some "origin"
  })
  let elementary_git = Git.(T {
    tarball = "${PACKAGE}-${VERSION}.tar.gz";
    dir = "elementary";
    prefix = "${PACKAGE}-${VERSION}";
    obj = Some "origin/master";
    uri = Some "http://git.enlightenment.org/core/elementary.git";
    remote = Some "origin"
  })

  let autoconf =
    Tarball ("${PACKAGE}-${VERSION}.tar.xz", "e891c3193029775e83e0534ac0ee0c4c711f6d23")
  let automake =
    Tarball ("${PACKAGE}-${VERSION}.tar.xz", "2ced676f6b792a95c5919243f81790b1172c7f5b")
  let libtool =
    Tarball ("${PACKAGE}-${VERSION}.tar.xz", "a62d0f9a5c8ddf2de2a3210a5ab712fd3b4531e9")
  let gettext =
    Tarball ("gettext-${VERSION}.tar.gz", "a32c19a6e39450748f6e56d2ac6b8b0966a5ab05")
end

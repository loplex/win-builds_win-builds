let builder =
  let open Config in
  let build = Arch.slackware in (* XXX *)
  let host = Arch.slackware in (* XXX *)
  let target = Arch.slackware in (* XXX *)
  let prefix = Prefix.t ~build ~host ~target in
  let logs, yyoutput = Builder.logs_yyoutput ~nickname:prefix.Prefix.nickname in
  let open Arch in
  let open Prefix in
  let open Builder in
  {
    name = "native_toolchain";
    prefix; logs; yyoutput;
    path = Env.Prepend [ bindir prefix ];
    pkg_config_path = Env.Prepend [ Filename.concat prefix.libdir "pkgconfig" ];
    pkg_config_libdir = Env.Keep;
    tmp = Env.Set [ Filename.concat prefix.Prefix.yyprefix "tmp" ];
    target_prefix = None;
    cross_prefix  = None;
    native_prefix = None;
    packages = [];
  }

let add_full =
  Config.Builder.register ~builder

let add = add_full ?outputs:None

let ocaml = add ("ocaml", None)
  ~dir:"slackbuilds.org/ocaml"
  ~dependencies:[]
  ~version:"4.01.0-trunk"
  ~build:2
  ~sources:[
    "${PACKAGE}-${VERSION}.tar.gz", "8996881034bec1c222ed91259238ea151b42a11d";
  ]

let lua = add ("lua", None)
  ~dir:"slackbuilds.org/development"
  ~dependencies:[]
  ~version:"5.1.5"
  ~build:1
  ~sources:[
    "${PACKAGE}-${VERSION}.tar.gz", "b3882111ad02ecc6b972f8c1241647905cb2e3fc";
    "${PACKAGE}.pc", "";
    "src_makefile", "";
  ]

let efl = add ("efl", Some "for-your-tools-only")
  ~dir:"slackbuilds.org/libraries"
  ~dependencies:[ lua ]
  ~version:"1.11.2"
  ~build:1
  ~sources:[
    "${PACKAGE}-${VERSION}.tar.xz", "81007abb130e087d01101d082661ada0a8879568";
  ]

let elementary = add ("elementary", None)
  ~dir:"slackbuilds.org/libraries"
  ~dependencies:[ efl ]
  ~version:"1.11.2"
  ~build:1
  ~sources:[
    "${PACKAGE}-${VERSION}.tar.xz", "d756b9c4763beebfbf494b9d2ee42cc2828dd4d8";
  ]

let qt = add ("qt", Some "native")
  ~dir:"slackware64-current/l"
  ~dependencies:[]
  ~version:"5.3.1"
  ~build:1
  ~sources:[
    "qt-everywhere-opensource-src-${VERSION}.tar.xz", "66b33ea66eb05a864e7ae417179ea24c8a45ec10";
    "Qt.pc", "";
    "0001-configure-use-pkg-config-for-libpng.patch", "";
    "0002-Use-widl-instead-of-midl.-Also-set-QMAKE_DLLTOOL-to-.patch", "";
    "0003-Tell-qmake-to-use-pkg-config.patch", "";
    "qt.fix.broken.gif.crash.diff.gz", "";
    "qt.mysql.h.diff.gz", "";
    "qt.webkit-no_Werror.patch.gz", "";
    "qt.yypkg.script", "";
    "qt5-dont-add-resource-files-to-qmake-libs.patch", "";
    "qt5-dont-build-host-libs-static.patch", "";
    "qt5-qmake-implib-dll-a.patch", "";
    "qt5-use-system-zlib-in-host-libs.patch", "";
    "qt5-workaround-qtbug-29426.patch", "";
  ]

let _all = add ("all", None)
  ~dir:""
  ~dependencies:[ lua; qt; efl; elementary ]
  ~version:"0.0.0"
  ~build:1
  ~sources:[]

let _all_but_qt = add ("all_but_qt", None)
  ~dir:""
  ~dependencies:[ lua; efl; elementary ]
  ~version:"0.0.0"
  ~build:1
  ~sources:[]

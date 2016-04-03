let do_adds builder =
  let open Sources in
  let add = Worker.register ~builder in

#use "slackware/d/autoconf/wb.ml"
#use "slackware/d/libtool/wb.ml"
#use "slackware/d/automake/wb.ml"
#use "slackware/l/gmp/wb.ml"
#use "slackware/l/mpfr/wb.ml"
#use "slackware/l/libmpc/wb.ml"
#use "slackbuilds.org/development/lua/wb.ml"
#use "slackware/d/pkg-config/wb-common.ml"
#use "slackware/d/pkg-config/wb-only-pkg-m4.ml"
#use "slackbuilds.org/win-builds/musl-private/wb.ml"
#use "slackbuilds.org/development/luajit/wb.ml"
  let luajit = luajit_add ~dependencies:[ musl_private ] in
#use "slackbuilds.org/libraries/efl/wb-common.ml"
#use "slackbuilds.org/libraries/efl/wb-for-your-tools-only.ml"
#use "slackbuilds.org/libraries/elementary/wb-for-your-tools-only.ml"
#use "slackbuilds.org/win-builds/mingw-w64/wb-common.ml"
#use "slackbuilds.org/win-builds/gendef/wb.ml"
#use "slackbuilds.org/win-builds/genidl/wb.ml"
#use "slackbuilds.org/win-builds/genpeimg/wb.ml"
#use "slackbuilds.org/win-builds/widl/wb.ml"
#use "slackbuilds.org/win-builds/examine/wb.ml"
  let examine = examine_add ~dependencies:[] in
#use "slackbuilds.org/ocaml/ocaml/wb.ml"
let ocaml = ocaml_add ~dependencies:[ musl_private ] ~native_deps:[] in
#use "slackware/a/file/wb.ml"
  let file = file_add ~dependencies:[] in

#extras

  let _all = add ("all", None)
    ~dir:""
    ~dependencies:[ autoconf; automake; libtool; lua; elementary;
      gendef; genidl; genpeimg; widl; gmp; mpfr; libmpc; examine ]
    ~version:"0.0.0"
    ~build:1
    ~sources:[]
    ~outputs:[]
  in

  ignore [ ocaml ]

let () =
  List.iter do_adds Builders.Native_toolchain.[ builder ]

let add =
  Worker.register ~builder:Builders.Native_toolchain.builder

let _ =
  let open Sources in
#use "slackware64-current/d/autoconf/wb.ml"
#use "slackware64-current/d/libtool/wb.ml"
#use "slackware64-current/d/automake/wb.ml"
#use "slackware64-current/l/gmp/wb.ml"
#use "slackware64-current/l/mpfr/wb.ml"
#use "slackware64-current/l/libmpc/wb.ml"
#use "slackbuilds.org/ocaml/ocaml/wb.ml"
  let ocaml = ocaml_add ~dependencies:[] in
#use "slackbuilds.org/development/lua/wb.ml"
#use "slackware64-current/d/pkg-config/wb-common.ml"
#use "slackware64-current/d/pkg-config/wb-only-pkg-m4.ml"
#use "slackbuilds.org/libraries/efl/wb-common.ml"
#use "slackbuilds.org/libraries/efl/wb-for-your-tools-only.ml"
#use "slackbuilds.org/libraries/elementary/wb-regular.ml"
#use "mingw/mingw-w64/wb-common.ml"
#use "mingw/gendef/wb.ml"
#use "mingw/genidl/wb.ml"
#use "mingw/genpeimg/wb.ml"
#use "mingw/widl/wb.ml"

#extras

  let _all = add ("all", None)
    ~dir:""
    ~dependencies:[ autoconf; automake; libtool; lua; efl; elementary;
      gendef; genidl; genpeimg; widl; gmp; mpfr; libmpc ]
    ~version:"0.0.0"
    ~build:1
    ~sources:[]
    ~outputs:[]
  in

  ignore [ ocaml ]

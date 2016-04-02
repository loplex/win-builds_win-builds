let do_adds builder =
  let open Sources in
  let add = Worker.register ~builder in

  let binutils_dependencies = [] in
#use "slackware64-current/d/binutils/wb.ml"
#use "slackbuilds.org/win-builds/mingw-w64/wb-common.ml"
#use "slackbuilds.org/win-builds/mingw-w64/wb-headers.ml"
  let gcc_core_dependencies = [ binutils; mingw_w64_headers ] in
  let gcc_native_dependencies = [ "mpfr"; "gmp"; "libmpc" ] in
#use "slackware64-current/d/gcc/wb-core.ml"
let mingw_w64_deps = [ binutils; gcc_core ] in
#use "slackbuilds.org/win-builds/mingw-w64/wb-full.ml"
(* pseh *)
  let gcc_full_dependencies = [ binutils; mingw_w64_full; gcc_core ] in
#use "slackware64-current/d/gcc/wb-full.ml"
#use "slackbuilds.org/win-builds/flexdll/wb.ml"
#use "slackbuilds.org/ocaml/ocaml/wb.ml"
  let ocaml = ocaml_add
    ~dependencies:[ binutils; flexdll; gcc_full; mingw_w64_full ]
    ~native_deps:[ "ocaml" ]
  in

#use "slackbuilds.org/ocaml/ocaml-findlib/wb.ml"
  let ocaml_findlib = ocaml_findlib_add
    ~dependencies:[ ocaml ]
    ~cross_deps:[]
    ~native_deps:[]
  in
#use "slackbuilds.org/win-builds/zz_config/wb.ml"

#extras

  let _all = add ("all", None)
    ~dir:""
    ~dependencies:[
      gcc_full; mingw_w64_full; binutils; mingw_w64_full; zz_config
    ]
    ~version:"0.0.0"
    ~build:1
    ~sources:[]
    ~outputs:[]
  in

  let _yypkg = add ("yypkg", None)
    ~dir:""
    ~dependencies:[ flexdll; ocaml; ocaml_findlib ]
    ~version:"1.0.0"
    ~build:1
    ~sources:[]
    ~outputs:[]
  in

  ()

let () =
  List.iter do_adds Builders.Cross_toolchain.[ builder_32; builder_64 ]

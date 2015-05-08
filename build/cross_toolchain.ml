let do_adds builder =
  let open Sources in
  let add_full = Worker.register ~builder in
  let add = add_full ?outputs:None in

#use "slackware64-current/d/binutils/wb.ml"
#use "mingw/mingw-w64/wb:headers.ml"
#use "slackware64-current/d/gcc/wb:core.ml"
#use "mingw/mingw-w64/wb:full.ml"
  let winpthreads = mingw_w64_add ("winpthreads", None)
    ~dependencies:[ binutils; gcc_core; mingw_w64_full ]
    ~build:2
  in
#use "slackware64-current/d/gcc/wb:full.ml"
#use "mingw/gendef/wb.ml"
#use "mingw/genidl/wb.ml"
#use "mingw/genpeimg/wb.ml"
#use "mingw/widl/wb.ml"
#use "mingw/flexdll/wb.ml"
#use "slackbuilds.org/ocaml/ocaml/wb.ml"
  let ocaml = ocaml_add
    ~dependencies:[ binutils; flexdll; gcc_full; mingw_w64_full ]
  in

#use "slackbuilds.org/ocaml/ocaml-findlib/wb.ml"
#use "mingw/zz_config/wb.ml"

#extras

  let _all = add_full ("all", None)
    ~dir:""
    ~dependencies:[
      gcc_full; mingw_w64_full; binutils; mingw_w64_full;
      gendef; genidl; genpeimg; widl; zz_config
    ]
    ~version:"0.0.0"
    ~build:1
    ~sources:[]
    ~outputs:[]
  in

  let _yypkg = add_full ("yypkg", None)
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

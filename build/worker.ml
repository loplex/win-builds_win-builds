open Config.Package
open Config.Builder
open Config.Prefix
open Config.Arch
open Sources

open Lib

let s_of_variant ?(pref="") = function Some v -> pref ^ v | None -> ""

let dict0 ~builder ~p =
  [
    "VERSION", "${VERSION}";
    "PACKAGE", p.package;
    "VARIANT", s_of_variant p.variant;
    "BUILD", string_of_int p.build;
    "TARGET_TRIPLET", p.prefix.target.triplet;
    "HOST_TRIPLET", p.prefix.host.triplet;
    "BUILD_TRIPLET", p.prefix.build.triplet;
  ]

let needs_rebuild ~version ~sources ~outputs =
  List.exists (fun o -> Sources.compare ~version ~sources ~output:o > 0) outputs

let run_build_shell ~devshell ~run p =
  let dir = p.dir ^/ p.package in
  let variant = match p.variant with None -> "" | Some s -> "-" ^ s in
  run [|
    "bash"; "-cex";
    String.concat "; " [
      sp "cd %S" dir;
      sp "export DESCR=\"$(sed -n 's;^[^:]\\+: ;; p' slack-desc | sed -e 's;\";\\\\\\\\\";g' -e 's;/;\\\\/;g' | tr '\\n' ' ')\"";
      sp "export PREFIX=\"$(echo \"${YYPREFIX}\" | sed 's;^/;;')\"";
      sp "export VERSION=%S" p.version;
      sp "export BUILD=%d" p.build;
      sp "if ! chown root:root / 2>/dev/null; then chown() { : ; }; export -f chown; fi";
      sp "if [ -e config%s ]; then . ./config%s; fi" variant variant;
      if not devshell then
        sp "exec bash -x %s.SlackBuild" p.package
      else
        sp "exec bash --norc"

    ]
  |] ()

let build_one_package ~builder ~outputs ~env p =
  let log =
    let filename = builder.logs ^/ (to_name p) in
    let flags = [ Unix.O_RDWR; Unix.O_CREAT; Unix.O_TRUNC ] in
    Unix.openfile filename flags 0o644
  in
  let run command = run ~stdout:log ~stderr:log ~env command in
  (try run_build_shell ~devshell:false ~run p with e ->
    List.iter (fun output -> try Unix.unlink output with _ -> ()) outputs;
    Unix.close log;
    raise e
  );
  ListLabels.iter outputs ~f:(fun output ->
    run [| "yypkg"; "--upgrade"; "--install-new"; output |] ()
  );
  Unix.close log

let build_one_devshell ~env p =
  run_build_shell ~devshell:true ~run:(run ~env) p

let build_one ~env ~builder p =
  let dict0 = dict0 ~builder ~p in
  let p_update ~dict ~p =
    {
      p with
      sources = List.map (substitute_variables_sources ~dir:p.dir ~package:p.package ~dict) p.sources;
      outputs = List.map (substitute_variables ~dict) p.outputs;
    }
  in
  let p =
    if p.version <> "git" then (
      let p = p_update ~dict:(("VERSION", p.version) :: dict0) ~p in
      Sources.get p;
      p
    )
    else (
      let p = p_update ~dict:dict0 ~p in
      Sources.get p;
      let p = { p with version = Sources.Git.version ~sources:p.sources } in
      let p = p_update ~dict:[ "VERSION", p.version ] ~p in
      p
    )
  in
  if (try Sys.getenv "DRYRUN" = "1" with Not_found -> false)
    && p.sources <> [] then
  (
    ListLabels.iter p.sources ~f:(function
      | Tarball (file, _) -> Lib.(log dbg " %s -> source=%s\n%!" p.package file)
      | _ -> ()
    )
  );
  if p.devshell then
    build_one_devshell ~env p
  else (
    let outputs = List.map ((^/) builder.yyoutput) p.outputs in
    if not (needs_rebuild ~version:p.version ~sources:p.sources ~outputs) then (
      progress "[%s] %s is already up-to-date.\n%!" builder.prefix.nickname (to_name p)
    )
    else (
      progress "[%s] Building %s\n%!" builder.prefix.nickname (to_name p);
      build_one_package ~builder ~outputs ~env p)
  )

let build_env builder =
  run ~env:[||] [| "mkdir"; "-p"; builder.yyoutput; builder.logs |] ();
  let env = env builder in
  (if not (Sys.file_exists builder.prefix.yyprefix)
    || Sys.readdir builder.prefix.yyprefix = [| |] then
  (
    run ~env [| "yypkg"; "--init" |] ();
    run ~env [| "yypkg"; "--config"; "--predicates"; "--set";
      Lib.sp "host=%s" builder.prefix.host.triplet |] ();
    run ~env [| "yypkg"; "--config"; "--predicates"; "--set";
      Lib.sp "target=%s" builder.prefix.target.triplet |] ();
    run ~env [| "yypkg"; "--config"; "--set-mirror";
      Lib.sp "http://win-builds.org/%s/packages/windows_%d"
        Lib.version builder.prefix.host.bits |] ();
  ));
  env

let register ~builder =
  let push p =
    builder.packages <- (builder.packages @ [ p ])
  in
  let shall_build = shall_build builder.name in
  let add_cross_builder_deps ~builder_name l =
    let v = String.uppercase builder_name in
    let new_deps = String.concat "," l in
    let cur = try Sys.getenv v with Not_found -> "" in
    Unix.putenv v (String.concat "," [ cur; new_deps ])
  in
  let rec colorize p =
    if not p.to_build then (
      p.to_build <- true;
      add_cross_builder_deps ~builder_name:"native_toolchain" p.native_deps;
      may (fun n -> add_cross_builder_deps ~builder_name:n p.cross_deps)
        builder.cross_name;
      List.iter colorize p.dependencies
    )
  in
  let add_aux p = (if shall_build p then colorize p); push p; p in
  let default_output =
    if builder.prefix.target <> builder.prefix.host then
      "${PACKAGE}-${VERSION}-${BUILD}-${TARGET_TRIPLET}-${HOST_TRIPLET}.txz"
    else
      "${PACKAGE}-${VERSION}-${BUILD}-${HOST_TRIPLET}.txz"
  in
  fun
    ?(outputs = [ default_output ])
    ?(native_deps = [])
    ?(cross_deps = builder.default_cross_deps)
    ~dir ~dependencies ~version ~build ~sources
    (package, variant)
  ->
    (if sources <> [] then (
      Lib.log Lib.dbg
        "Adding package %S %S %d.\n%!"
        (package ^ (s_of_variant ~pref:":" variant))
        version
        build;
    ));
    let sources =
      if dir <> "" then
        List.concat [
          (match variant with Some v -> [ WB ("config-" ^ v) ] | None -> []);
          [ WB "${PACKAGE}.SlackBuild" ];
          [ WB "${PACKAGE}.yypkg.script" ];
          sources
        ]
      else
        []
    in
    let p = {
      package; variant; dir; dependencies; native_deps; cross_deps;
      version; build;
      sources; outputs;
      to_build = false;
      devshell = false;
      prefix = builder.prefix;
    }
    in
    (* Automatically inject a "devshell" package and don't return it since it
     * makes no sense to have other packages depend on it. *)
    ignore (add_aux { p with devshell = true });
    add_aux p

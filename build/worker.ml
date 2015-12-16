open Config.Package
open Config.Builder
open Config.Prefix
open Config.Arch
open Sources

open Lib

let s_of_variant ?(pref="") = function Some v -> pref ^ v | None -> ""

let dict0 ~builder ~p:(c, (r : Config.Package.real)) =
  [
    "VERSION", "${VERSION}";
    "PACKAGE", c.package;
    "VARIANT", s_of_variant c.variant;
    "BUILD", string_of_int r.build;
    "TARGET_TRIPLET", r.prefix.target.triplet;
    "HOST_TRIPLET", r.prefix.host.triplet;
    "BUILD_TRIPLET", r.prefix.build.triplet;
  ]

let needs_rebuild ~version ~sources ~outputs =
  List.exists (fun o -> Sources.compare ~version ~sources ~output:o > 0) outputs

let run_build_shell ~devshell ~run ~p:(c, r) =
  run [|
    "bash";
    "./win-builds/package_support.sh";
    r.dir ^/ c.package;
    c.package;
    (match c.variant with None -> "" | Some s -> s);
    r.version;
    string_of_int r.build;
    string_of_bool devshell;
  |] ()

let build_one_package ~builder ~outputs ~env ~p:((c, r) as p) ~log =
  let run command = run ~stdout:log ~stderr:log ~env command in
  (try run_build_shell ~devshell:false ~run ~p with e ->
    List.iter (fun output -> try Unix.unlink output with _ -> ()) outputs;
    raise e
  );
  ListLabels.iter outputs ~f:(fun output ->
    run [| "yypkg"; "--upgrade"; "--install-new"; output |] ()
  )

let build_one_devshell ~env ~p =
  run_build_shell ~devshell:true ~run:(run ~env) ~p

let build_one ~env ~builder ~log ~p:((c, r) as p) =
  let dict0 = dict0 ~builder ~p in
  let p_update ~dict ~p:(c, r) =
    c, {
      r with
      sources = List.map (substitute_variables_sources ~dir:r.dir ~package:c.package ~dict) r.sources;
      outputs = List.map (substitute_variables ~dict) r.outputs;
    }
  in
  let ((c, r) as p) =
    if r.version <> "git" then (
      let p = p_update ~dict:(("VERSION", r.version) :: dict0) ~p in
      Sources.get p;
      p
    )
    else (
      let ((c, r) as p) = p_update ~dict:dict0 ~p in
      Sources.get p;
      let ((c, r) as p) = c, { r with version = Sources.Git.version ~r } in
      p_update ~dict:[ "VERSION", r.version ] ~p
    )
  in
  if r.sources <> [] then
  (
    ListLabels.iter r.sources ~f:(function
      | Tarball (file, _) -> Lib.(log dbg " %s -> source=%s\n%!" c.package file)
      | _ -> ()
    )
  );
  if not dryrun then (
    if c.devshell then (
      build_one_devshell ~env ~p;
      false
    )
    else (
      let outputs = List.map ((^/) builder.yyoutput) r.outputs in
      if not (needs_rebuild ~version:r.version ~sources:r.sources ~outputs) then (
        progress "[%s] %s is already up-to-date.\n%!" builder.prefix.nickname (to_name c);
        false
      )
      else (
        progress "[%s] Building %s\n%!" builder.prefix.nickname (to_name c);
        ignore (Unix.lseek log 0 Unix.SEEK_SET);
        Unix.ftruncate log 0;
        build_one_package ~builder ~outputs ~env ~p ~log;
        true
      )
    )
  )
  else
    false

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
    let set = set_of_env v in
    let set = ListLabels.fold_left l ~init:set ~f:(fun set e ->
      if not (List.mem e set) then
        e :: set
      else
        set
    )
    in
    Unix.putenv v (String.concat "," set)
  in
  let rec colorize = function
    | Virtual ( { to_build = false } as c)
    | Real ( { to_build = false } as c, _) ->
        c.to_build <- true;
        add_cross_builder_deps ~builder_name:"native_toolchain" c.native_deps;
        may (fun n -> add_cross_builder_deps ~builder_name:n c.cross_deps)
          builder.cross_name;
        List.iter colorize c.dependencies
    | Virtual ( { to_build = true } )
    | Provides ( { to_build = true }, _ )
    | Real ( { to_build = true }, _ ) ->
        ()
    | Provides ( { to_build = false } as c, alternatives) ->
        c.to_build <- true;
        (if not (List.exists (fun p -> (c_of p).to_build) alternatives) then (
         colorize (List.hd alternatives)
        ));

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
    ?alternatives
    ~dir ~dependencies ~version ~build ~sources
    (package, variant)
  ->
    let virt = dir = "" in
    let c = {
      package; variant; dependencies; native_deps; cross_deps;
      to_build = false; devshell = false;
    }
    in
    match virt, alternatives with
    | false, None ->
        (if sources <> [] then (
          Lib.log Lib.dbg
            "Adding package %S %S %d.\n%!"
            (package ^ (s_of_variant ~pref:":" variant))
            version
            build;
        ));
        let sources =
          if not virt then
            (match variant with Some v -> [ WB ("config-" ^ v) ] | None -> [])
            @ (WB "${PACKAGE}.SlackBuild"
            :: WB "${PACKAGE}.yypkg.script"
            :: sources)
          else
            []
        in
        let r = { dir; version; build; sources; outputs; prefix = builder.prefix } in
        (* Automatically inject a "devshell" package and don't return it since
         * it makes no sense to have other packages depend on it. *)
        (* TODO: s/Real/Devshell ? *)
        ignore (add_aux (Real (( { c with devshell = true } ), r)));
        add_aux (Real (c, r))
    | true, None ->
        add_aux (Virtual c)
    | false, Some alternatives ->
        assert (native_deps = [] && (cross_deps = [] || cross_deps = builder.default_cross_deps) && dependencies = []);
        add_aux (Provides (c, alternatives))
    | true, Some _ ->
        assert false


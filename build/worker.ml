open Config.Package
open Config.Builder
open Config.Prefix
open Config.Arch
open Sources

open Lib

let needs_rebuild ~version ~sources ~outputs =
  List.exists (fun o -> Sources.compare ~version ~sources ~output:o > 0) outputs

let run_build_shell ~devshell ~run ~p:(c, r) =
  run [|
    "bash";
    "./package_support.sh";
    r.dir ^/ c.package;
    c.package;
    (match c.variant with None -> "" | Some s -> s);
    r.version;
    string_of_int r.build;
    string_of_bool devshell;
  |] ()

let build_one_package ~outputs ~env ~p:((c, _) as p) ~log =
  let run command = run ~stdout:log ~stderr:log ~env command in
  (try run_build_shell ~devshell:false ~run ~p with e ->
    List.iter (fun output -> try Unix.unlink output with _ -> ()) outputs;
    raise e
  );
  ListLabels.iter outputs ~f:(fun output ->
    run [| "yypkg"; "--upgrade"; "--install-new"; output |] ()
  )

let devshell ~env ~p =
  run_build_shell ~devshell:true ~run:(run ~env) ~p

let build_one ~progress ~get ~env ~builder ~log ~p:((c, r) as p) =
  let name = to_name c in
  ListLabels.iter r.sources ~f:(function
    | Tarball (file, _) -> Lib.(log dbg " %s -> source=%s\n%!" c.package file)
    | _ -> ()
  );
  progress ~flush:false (Lib.sp "%s(source)" name);
  let (c, r) as p = match get p with p, None -> p | p, Some exn -> raise exn in
  let outputs = List.map ((^/) builder.yyoutput) r.outputs in
  if not (needs_rebuild ~version:r.version ~sources:r.sources ~outputs) then (
    progress ~flush:false (Lib.sp "%s(up-to-date)" name);
    false
  )
  else (
    if not dryrun then (
      ignore (Unix.lseek log 0 Unix.SEEK_SET);
      Unix.ftruncate log 0;
      progress ~flush:false (Lib.sp "%s(build)" name);
      build_one_package ~outputs ~env ~p ~log;
    );
    progress ~flush:true (Lib.sp "%s(done)" name);
    not dryrun
  )

let build_env builder =
  run ~env:[||] [| "mkdir"; "-p"; builder.yyoutput; builder.logs |] ();
  let env = env builder in
  (if not (Sys.file_exists builder.prefix.yyprefix)
    || Sys.readdir builder.prefix.yyprefix = [| |] then
  (
    run ~env [| "yypkg"; "--init" |] ();
    run ~env [| "yypkg"; "--config"; "--predicates"; "--set";
      Lib.sp "host=%s" builder.prefix.host |] ();
    run ~env [| "yypkg"; "--config"; "--predicates"; "--set";
      Lib.sp "target=%s" builder.prefix.target |] ();
    run ~env [| "yypkg"; "--config"; "--predicates"; "--set"; "dbg=yes" |] ();
    run ~env [| "yypkg"; "--config"; "--set-mirror";
      Lib.sp "http://win-builds.org/%s/packages/%s"
        Lib.version builder.prefix.name |] ();
  ));
  env

let register ~builder =
  let push p =
    builder.packages <- (builder.packages @ [ p ])
  in
  let shall_build = shall_build builder.prefix.name in
  let add_cross_builder_deps ~builder_name l =
    let v = String.uppercase_ascii builder_name in
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
        (* TODO: should we introduce a Devshell type? *)
        ignore (add_aux (Real (( { c with devshell = true } ), r)));
        add_aux (Real (c, r))
    | true, None ->
        add_aux (Virtual c)
    | false, Some alternatives ->
        assert (native_deps = [] && (cross_deps = [] || cross_deps = builder.default_cross_deps) && dependencies = []);
        add_aux (Provides (c, alternatives))
    | true, Some _ ->
        assert false


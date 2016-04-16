open Config.Prefix
open Config.Package
open Config.Builder
open Lib

let log ~builder ~p:(c, r) =
  let path = builder.logs ^/ (to_name c) in
  path, Unix.openfile path [ Unix.O_RDWR; Unix.O_CREAT; ] 0o644

let build ~get ~failer ~progress builder =
  let progress ~flush s = Statusline.write ~flush progress s in
  let did_something = ref false in
  let env = Worker.build_env builder in
  let rec aux = function
    | Virtual { package = "download" } :: tl ->
        run ~env [| "yypkg"; "--web"; "--auto"; "yes" |] ();
        aux tl
    | Real (({ devshell = true }, _) as p) :: tl ->
        Worker.devshell ~env ~p
    | Real ((c, _) as p) :: tl -> (
        let log_path, log_fd = log ~p ~builder in
        try
          did_something :=
            (Worker.build_one ~progress ~get ~builder ~env ~p ~log:log_fd) || !did_something;
          if !failer then
            Lib.(log cri "[%s] Aborting because another thread failed.\n%!"
              builder.prefix.name)
          else
            aux tl
        with _ -> (
          failer := true;
          Lib.(log cri "\n[%s] *** ERROR ***\n" builder.prefix.name);
          Lib.(log cri "[%s] Build of %s failed; read the log at:\n  %S\n\n%!"
            builder.prefix.name (to_name c) log_path)
        );
        Unix.close log_fd
      )
    | Provides _ :: tl
    | Virtual _ :: tl ->
        aux tl
    | [] ->
        ()
  in
  aux builder.packages;
  if !did_something && not dryrun then (
    progress ~flush:false "repository setup";
    (try
      run [| "yypkg"; "--repository"; "--generate"; builder.yyoutput |] ()
    with _ -> Printf.eprintf "ERROR: Couldn't create repository!\n%!");
    progress ~flush:true "done";
  )

(* This is the only acceptable umask when building packets. Any other gives
 * wrong permissions in the packages, like 711 for /usr, and will break
 * systems. *)
let () = ignore (Unix.umask 0o022)

let builders =
  Builders.[
    [ Native_toolchain.builder ];
    [ Cross_toolchain.builder_32; Cross_toolchain.builder_64 ];
    [ Windows.builder_32; Windows.builder_64; Windows.builder_ministat ];
  ]

let () =
  let build ~get builders =
    let failer = ref false in
    let run_builder builder =
      Thread.create (fun builder ->
        let progress = Statusline.create builder.shortname in
        (try build ~get ~failer ~progress builder with _ -> ());
        Statusline.release progress
      ) builder
    in
    let builders = List.filter (fun b -> b.packages <> []) builders in
    List.(iter Thread.join (map run_builder builders));
    (if !failer then failwith "Build failed.")
  in
  let builders = List.map (List.map (fun b ->
    { b with packages = List.filter (fun p -> (c_of p).to_build) b.packages }))
  builders in
  let get =
    Sources.get (List.(flatten (map (fun b -> b.packages) (flatten builders))))
  in
  List.iter (build ~get) builders

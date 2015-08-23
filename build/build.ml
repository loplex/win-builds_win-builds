open Config.Prefix
open Config.Package
open Config.Builder
open Lib

let log ~builder ~p:((c, r) as p) =
  let path = builder.logs ^/ (to_name c) in
  path, Unix.openfile path [ Unix.O_RDWR; Unix.O_CREAT; Unix.O_TRUNC ] 0o644

let build ~failer builder =
  let did_something = ref false in
  let packages = List.filter (fun p -> (c_of p).to_build) builder.packages in
  (if packages <> [] then (
    (* progress "[%s] Checking %s\n%!"
      builder.prefix.nickname
      (String.concat ", " (List.map to_name packages)); *)
    let env = Worker.build_env builder in
    let rec aux = function
      | Virtual { package = "download" } :: tl ->
          run ~env [| "yypkg"; "--web"; "--auto"; "yes" |] ();
          aux tl
      | Real ((c, _) as p) :: tl ->
          let log_path, log_fd = log ~p ~builder in
          (if not (try Worker.build_one ~builder ~env ~p ~log:log_fd; true with _ -> false) then (
            failer := true;
            Lib.(log cri
              "[%s] Build of %s failed; read and/or share the build log at:\n  %S.\n"
              builder.prefix.nickname
              (to_name c)
              log_path
            )
          )
          else (
            did_something := true;
            if !failer then
              prerr_endline "Aborting because another thread did so."
            else
              aux tl
          ));
          Unix.close log_fd
      | Provides _ :: tl
      | Virtual _ :: tl ->
          aux tl
      | [] ->
          ()
    in
    aux packages
  ));
  if !did_something && not dryrun then (
    progress "[%s] Setting up repository.\n%!" builder.prefix.nickname;
    try
      run [| "yypkg"; "--repository"; "--generate"; builder.yyoutput |] ()
    with _ -> Printf.eprintf "ERROR: Couldn't create repository!\n%!"
  )

(* This is the only acceptable umask when building packets. Any other gives
 * wrong permissions in the packages, like 711 for /usr, and will break
 * systems. *)
let () = ignore (Unix.umask 0o022)

let () =
  let build builders =
    let failer = ref false in
    let run_builder builder = Thread.create (build ~failer) builder in
    let enough_ram = Sys.command "awk -F' ' '/MemAvailable/ { if ($2 > (2*1024*1024)) { exit 0 } else { exit 1 } }' /proc/meminfo" in
    (if enough_ram = 0 then
      List.iter Thread.join (List.map run_builder builders)
    else (
      Printf.eprintf "Detected less than 2GB of free RAM; building sequentially.\n%!";
      List.iter (fun builder -> Thread.join (run_builder builder)) builders;
    )
    );
    (if !failer then failwith "Build failed.")
  in
  List.iter build Builders.[
    [ Native_toolchain.builder ];
    [ Cross_toolchain.builder_32; Cross_toolchain.builder_64 ];
    [ Windows.builder_32; Windows.builder_64 ];
  ]

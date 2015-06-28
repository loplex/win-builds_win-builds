open Config.Prefix
open Config.Package
open Config.Builder
open Lib

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
          if not (try Worker.build_one ~builder ~env ~p; true with _ -> false) then (
            failer := true;
            prerr_endline ("Build of " ^ c.package ^ " failed.")
          )
          else (
            did_something := true;
            if !failer then
              prerr_endline "Aborting because another thread did so."
            else
              aux tl
          )
      | Provides _ :: tl
      | Virtual _ :: tl ->
          aux tl
      | [] ->
          ()
    in
    aux packages
  ));
  if !did_something then (
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

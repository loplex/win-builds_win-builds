type poison = Poison

let (^/) a b = String.concat "/" [ a; b ]

let cri = 0
let err = 1
let wrn = 2
let inf = 3
let dbg = 4

let log_threshold =
  try
    match Sys.getenv "LOGLEVEL" with
    | "CRI" | "cri" -> cri
    | "ERR" | "err" -> err
    | "WRN" | "wrn" -> wrn
    | "INF" | "inf" -> inf
    | "DBG" | "dbg" -> dbg
    | s -> try int_of_string s with _ -> inf
  with _ -> inf

let log level =
  (if log_threshold >= level then Printf.fprintf else Printf.ifprintf) stderr

let cond_log level b s =
  (if not b then log level s); b

let sp = Printf.sprintf

type command = {
  cmd : string;
  pid : int;
}

let waitpid log_level command =
  let f = log log_level in
  match snd (Unix.waitpid [] command.pid) with
  | Unix.WEXITED i ->
      f "Command `%s' returned %d.\n%!" command.cmd i;
      if i <> 0 then failwith (sp "Failed process [%d]: `%s'\n'" i command.cmd)
  | Unix.WSIGNALED i ->
      f "Command `%s' has been signaled with signal %d.\n%!" command.cmd i
  | Unix.WSTOPPED i ->
      f "Command `%s' has been stopped with signal %d.\n%!" command.cmd i

let run ?(stdin=Unix.stdin) ?(stdout=Unix.stdout) ?(stderr=Unix.stderr) ?env a =
  let cmd = String.concat " " (Array.to_list a) in
  log dbg "Running `%s'%!" cmd;
  let env = match env with
    | None -> Unix.environment ()
    | Some env -> env
  in
  log dbg ", env = { %s }%!" (String.concat ", " (Array.to_list env));
  let pid = Unix.create_process_env a.(0) a env stdin stdout stderr in
  log dbg ", pid = %d.\n%!" pid;
  (fun () -> waitpid dbg { pid = pid; cmd = cmd })

(* XXX: only valid for short reads *)
let run_and_read ?env cmd =
  let buf = Bytes.create 4096 in
  let pipe_read, pipe_write = Unix.pipe () in
  let waiter = run ?env ~stdout:pipe_write cmd in
  Unix.close pipe_write;
  let l = Unix.read pipe_read buf 0 (Bytes.length buf) in
  Unix.close pipe_read;
  waiter ();
  Bytes.(to_string (sub buf 0 (l-1))) (* (l-1) because of a trailing \n *)

let make_path_absolute_if_not path =
  let cwd = Sys.getcwd () in
  if Filename.is_relative path then
    cwd ^/ path
  else
    path

let may f = function
  | Some x -> f x
  | None -> ()

let work_dir =
  if Array.length Sys.argv < 2 then (
    log cri "Not enough arguments.\n%!";
    exit 1
  )
  else
    make_path_absolute_if_not Sys.argv.(1)

let version = Sys.getenv "VERSION"

let set_of_env n =
  Str.split (Str.regexp ",") (try (Sys.getenv n) with Not_found -> "")

let dryrun =
  not (try Sys.getenv "DRYRUN" = "0" with Not_found -> true)

let substitute_variables ~dict s =
  let f k =
    try
      log dbg "Associating %S in %S.\n%!" k s;
      List.assoc k dict
    with Not_found as exn ->
      log cri "Couldn't resolve variable %S in %S.\n%!" k s;
      raise exn
  in
  let b = Buffer.create (String.length s) in
  Buffer.add_substitute b f s;
  let s = Buffer.contents b in
  log dbg "Result: %S.\n%!" s;
  s

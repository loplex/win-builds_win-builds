open Config.Package
open Lib

type source += Tarball of (string * string)
type source += WB of string
type source += Patch of string

module Patch = struct
  let get _ = ()
end

module Git = struct
  type t = {
    tarball : string;
    dir : string;
    prefix : string;
    obj : string option;
    uri : string option;
    remote : string option;
  }
  type source += T of t

  let system ?env a =
    (* TODO: remove the String.escaped and the non-system variant *)
    let cmd = String.concat " " (Array.to_list (Array.map String.escaped a)) in
    run ?env [| Sys.getenv "SHELL"; "-c"; cmd |] ()

  let run ?env a =
    run ?env a ()

  let with_git_dir ~dir args (f : ?env:_ -> _ -> _) =
    let env = Array.concat [ [| Lib.sp "GIT_DIR=%s/.git" dir |]; Unix.environment () ] in
    f ~env (Array.of_list args)

  let git_dir_rev_parse ~dir args =
    with_git_dir ~dir ["git"; "rev-parse"; "--verify"; "--short"; args ] run_and_read

  let tar ~tarball ~prefix ~dir =
    log wrn "Building archive from git at %S.\n%!" tarball;
    with_git_dir ~dir [
      "git"; "ls-files";
      "|"; "tar"; "c"; "-C"; dir; "-T"; "-"; "--transform"; sp "s;^;%s/;" prefix;
      "|"; "gzip"; "-1";
      ">"; tarball
    ] system

  let archive ~obj ~tarball ~prefix ~dir =
    log wrn "Building archive from git at %S.\n%!" tarball;
    with_git_dir ~dir [
      "git"; "archive"; sp "--prefix=%s/" prefix; obj;
      "|"; "gzip"; "-1";
      ">"; tarball
    ] system

  let fetch ~remote ~dir =
    let f r = with_git_dir ~dir ("git" :: "fetch" :: r) run in
    match remote with
    | Some remote -> f [ remote ]
    | None -> f []

  let remote_add ~uri ~dir ?remote () =
    (if (not (Sys.file_exists dir)) || (not (Sys.is_directory dir)) then
      match remote with
      | None ->
          log dbg "Cloning %S at %S.\n%!" uri dir;
          run [| "git"; "clone"; uri; dir |]
      | Some remote ->
          log dbg "Initializing a git repository at %S.\n%!" dir;
          run [| "git"; "init"; dir |]
    );
    may (fun remote ->
      log dbg "Ensuring remote %S to %S at %S.\n%!" remote uri dir;
      with_git_dir ~dir [
        "git"; "remote"; "-v"; "show";
        "|"; "grep"; "-q"; Lib.sp "'^%s[[:blank:]]%s[[:blank:]](fetch)$'" remote uri;
        "||"; "git"; "remote"; "add"; remote; uri
      ] system
    ) remote

  let version ~r =
    match List.find_all (function T _ -> true | _ -> false) r.sources with
    | [ T { dir; obj } ] -> (
        match obj with
        | Some obj -> git_dir_rev_parse ~dir obj
        | None -> "disk" (* TODO: isn't propagated to the replacement list *)
      )
    | [] ->
        (* return the same version if no git sources have been found; this
         * makes it possible to not have to wonder whether there's at least one
         * git source or not *)
        r.version
    | _ ->
        assert false

  let get { tarball; dir; obj; uri; remote; prefix } =
    match obj with
    | None ->
        if not (Sys.file_exists tarball) then (
          tar ~tarball ~git ~dir ~prefix
        )
    | Some obj -> (
        may (fun uri -> remote_add ~uri ~dir ?remote ()) uri;
        fetch ~remote ~dir;
        let version = git_dir_rev_parse ~dir obj in
        let subst = substitute_variables ~dict:[ "VERSION", version ] in
        let tarball = subst tarball in
        let dir = subst dir in
        let prefix = subst prefix in
        if not (Sys.file_exists tarball) then (
          archive ~tarball ~obj ~prefix ~dir
        )
    )
end

module Tarball = struct
  let get (file, sha1) =
    let download ~file =
      run [| "curl"; "--silent"; "-o"; file; (Sys.getenv "MIRROR") ^/ file |] ()
    in
    let file_matches_sha1 ~sha1 ~file =
      if sha1 = "" then (
        log dbg "File %S exists and has no SHA1 constraint.\n%!" file;
        true
      )
      else (
        let pipe_read, pipe_write = Unix.pipe () in
        let line = sp "%s *%s\n" sha1 file in
        let l = String.length line in
        assert (l = Unix.write pipe_write line 0 l);
        Unix.close pipe_write;
        let res = (try
          run ~stdin:pipe_read
            [| "sha1sum"; "--status"; "--check"; "--strict" |] ();
          log dbg "File %S exists with the right SHA1.\n%!" file;
          true
        with Failure _ ->
          log dbg "File %S exists and doesn't have the right SHA1.\n%!" file;
          false
        )
        in
        Unix.close pipe_read;
        res
      )
    in
    let rec get_file ?(tries=0) ~sha1 ~file =
      let retry () =
        log cri "Failed retrieving file %S (SHA1=%s).\n" file sha1;
        if tries > 1 then (
          log cri "Trying again: %d attempt(s) left.\n" tries;
          get_file ~tries:(tries-1) ~sha1 ~file
        )
        else (
          log cri "No attempt left.\nFAILED!\n";
          (try Sys.remove file with Sys_error _ -> ());
          failwith (sp "Download of %S (SHA1=%s)." file sha1)
        )
      in
      let matches =
        try
          (if not (Sys.file_exists file) then (
            log dbg "File %S doesn't exist: downloading.\n%!" file;
            download ~file
          ));
          file_matches_sha1 ~sha1 ~file
        with
          _ -> false
      in
      if not matches then
        retry ()
      else
        ()
    in
    get_file ~tries:3 ~sha1 ~file

  let get ~package (file, sha1) =
    get (file, sha1)
end

let p_update ~dict ~p:(c, r) =
  let substitute_variables_sources source =
    let sources_dir_ize s = (r.dir ^/ c.package) ^/ s in
    let subst s = substitute_variables ~dict s in
    match source with
    | WB file -> WB (sources_dir_ize (subst file))
    | Patch file -> Patch (sources_dir_ize (subst file))
    | Tarball (file, s) -> Tarball (sources_dir_ize (subst file), s)
    | Git.T ({ Git.tarball; prefix; dir} as x) ->
        Git.(T { x with
          tarball = sources_dir_ize (subst tarball);
          dir = sources_dir_ize (subst dir);
          prefix = subst prefix;
        })
    | x -> x
  in
  c, {
    r with
    sources = List.map substitute_variables_sources r.sources;
    outputs = List.map (substitute_variables ~dict) r.outputs;
  }

let get l =
  let obtained = ref [] in
  let l = List.fold_right (fun p accu -> match p with Real p -> p :: accu | _ -> accu) l [] in
  let m = Mutex.create () in
  let cond = Condition.create () in
  ignore (Thread.create (fun l ->
    List.iter (fun ((c, r) as p) ->
      if not (List.mem_assoc p !obtained) then (
        let res = (try
          ListLabels.iter r.sources ~f:(function
            | WB _ -> ()
            | Tarball y -> Tarball.get ~package:c.package y
            | Git.T y -> Git.get y
            | Patch y -> Patch.get y
            | _ -> assert false
          );
          let ((c, r) as p) = c, { r with version = Git.version ~r } in
          let p = p_update ~dict:[ "VERSION", r.version ] ~p in
          p, None
        with exn ->
          p, Some exn
        )
        in
        Mutex.lock m;
        obtained := res :: !obtained;
        Mutex.unlock m;
        Condition.broadcast cond
      );
    ) l;
  ) l);
  (fun ((c, r) as p) ->
    let pred ((c', _r'), _res) =
      (c'.package = c'.package) && (c.variant = c'.variant)
    in
    Mutex.lock m;
    while not (List.exists pred !obtained) do
      Condition.wait cond m
    done;
    Mutex.unlock m;
    List.find pred !obtained)

let version_of_package package =
  let o = run_and_read [|
    "yypkg"; "--package"; "--script"; "--metadata"; "--version"; package |]
  in
  Scanf.sscanf o "%S:\"version\":%S" (fun _ v -> v)

let compare ~version ~sources ~output =
  let ts f =
    f, (try Unix.((lstat f).st_mtime) with _ -> 0.)
  in
  let ts_output = ts output in
  let compare_f (a_f, a_ts) (b_f, b_ts) =
    let x = compare a_ts b_ts in
    (fun s -> (log dbg "%S is %s %S.\n%!" a_f s b_f))
      (if x < 0 then "older than"
        else (
          if x > 0 then "newer than"
          else "as old as"));
    x
  in
  let compare_one = function
    | Patch patch -> compare_f (ts patch) ts_output
    | WB file -> compare_f (ts file) ts_output
    | Tarball (file, _) -> compare_f (ts file) ts_output
    | Git.T { Git.obj = None } ->
        1
    | Git.T _ ->
        if Sys.file_exists output then
          try
            abs (compare version (version_of_package output))
          with
            _ -> 1
        else
          1
    | _ -> assert false
  in
  List.fold_left (fun accu s -> max accu (compare_one s)) (-1) sources

let chose_source =
  let l = set_of_env "FROM_VCS" in
  fun ~name ~version ~vcs ~default ->
    if List.mem name l then
      vcs, "git"
    else
      default, version

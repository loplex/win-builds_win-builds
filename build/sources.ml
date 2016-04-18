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

  let system ?env l =
    run ?env [| Sys.getenv "SHELL"; "-c"; String.concat " " l |] ()

  let git_sha1 ~dir obj =
    run_and_read [| "git"; "-C"; dir; "rev-parse"; "--verify"; "--short"; obj |]

  let tar ~tarball ~prefix ~dir =
    log wrn "Building tarball from git at %S.\n%!" tarball;
    run [|
      "tar"; "cf"; tarball;
      "--exclude-vcs"; "--exclude-vcs-ignores";
      "-C"; dir;
      ".";
      "--transform"; sp "s;^\\.;%s;" prefix
    |] ()

  let archive ~obj ~tarball ~prefix ~dir =
    log wrn "Building archive from git at %S.\n%!" tarball;
    run [|
      "git"; "-C"; dir; "archive"; sp "--prefix=%s/" prefix; "-o"; tarball; obj;
    |] ()

  let fetch ~dir = function
    | Some remote -> run [| "git"; "-C"; dir; "fetch"; remote |] ()
    | None -> run [| "git"; "-C"; dir; "fetch" |] ()

  let remote_add ~uri ~dir ?remote () =
    (if (not (Sys.file_exists dir)) || (not (Sys.is_directory dir)) then
      match remote with
      | None ->
          log dbg "Cloning %S at %S.\n%!" uri dir;
          run [| "git"; "clone"; uri; dir |] ()
      | Some remote ->
          log dbg "Initializing a git repository at %S.\n%!" dir;
          run [| "git"; "init"; dir |] ()
    );
    may (fun remote ->
      log dbg "Ensuring remote %S to %S at %S.\n%!" remote uri dir;
      system [
        "git"; "-C"; dir; "remote"; "-v"; "show";
        "|"; "grep"; "-q"; sp "'^%s[[:blank:]]%s[[:blank:]](fetch)$'" remote uri;
        "||"; "git"; "-C"; dir; "remote"; "add"; remote; uri
      ]
    ) remote

  let version_of_obj ~dir = function
    | Some obj -> git_sha1 ~dir obj
    | None -> "disk"

  let version ~r =
    match List.find_all (function T _ -> true | _ -> false) r.sources with
    | [ T { dir; obj } ] -> version_of_obj ~dir obj
    (* Return the same version if no git sources have been found; this
     * makes it possible to not have to wonder whether there's at least one
     * git source or not *)
    | [] -> r.version
    | _ -> assert false

  let get { tarball; dir; obj; uri; remote; prefix } =
    may (fun _ ->
      may (fun uri -> remote_add ~uri ~dir ?remote ()) uri;
      fetch ~dir remote;
    ) obj;
    let version = version_of_obj ~dir obj in
    let subst = substitute_variables ~dict:[ "VERSION", version ] in
    let tarball = subst tarball in
    let dir = subst dir in
    let prefix = subst prefix in
    (match obj with
    | None -> tar ~tarball ~dir ~prefix
    | Some obj when not (Sys.file_exists tarball) ->
        archive ~obj ~tarball ~dir ~prefix
    | Some obj -> ()
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

let sources_update ((c, r) as p) =
  let dict = dict p in
  let sources_dir_ize s = (r.dir ^/ c.package) ^/ s in
  let subst s = substitute_variables ~dict s in
  let subst_sources = function
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
  ( c, { r with sources = List.map subst_sources r.sources } )

let outputs_update ((c, r) as p) =
  ( c, { r with outputs = List.map (substitute_variables ~dict:(dict p)) r.outputs } )

let get l =
  let pred (c, _r) ((c', _r'), _res) =
    (c'.package = c'.package) && (c.variant = c'.variant)
  in
  let obtained = ref [] in
  let l = List.fold_right (fun p accu -> match p with Real p -> p :: accu | _ -> accu) l [] in
  let m = Mutex.create () in
  let cond = Condition.create () in
  ignore (Thread.create (fun l ->
    List.iter (fun ((c, r) as p) ->
      if not (List.exists (pred p) !obtained) then (
        let (c, r) as p = sources_update p in
        let res = (try
          ListLabels.iter r.sources ~f:(function
            | WB _ -> ()
            | Tarball y -> Tarball.get ~package:c.package y
            | Git.T y -> Git.get y
            | Patch y -> Patch.get y
            | _ -> assert false
          );
          (outputs_update (c, { r with version = Git.version ~r })), None
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
    Mutex.lock m;
    while not (List.exists (pred p) !obtained) do
      Condition.wait cond m
    done;
    Mutex.unlock m;
    List.find (pred p) !obtained)

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
    | Git.T { Git.obj = None } -> 1
    | Git.T _ ->
        (try abs (compare version (version_of_package output)) with _ -> 1)
    | _ -> assert false (* Needed because source is an extensible variant. *)
  in
  List.fold_left (fun accu s -> max accu (compare_one s)) (-1) sources

let chose_source =
  let l = set_of_env "FROM_VCS" in
  fun ~name ~version ~vcs ~default ->
    if List.mem name l then
      vcs, "git"
    else
      default, version

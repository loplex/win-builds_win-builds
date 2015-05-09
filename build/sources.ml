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

  let git_invoke ~dir =
    let git args =
      Array.of_list ("git" :: (sp "--git-dir=%s/.git" dir) :: args)
    in
    (fun op args ->
      match op with
      | `Archive -> git ("archive" :: args)
      | `Fetch -> git ("fetch" :: args)
      | `Remote -> git ("remote" :: args)
      | `LsFiles -> git ( "ls-files" :: args)
    )

  let tar ~tarball ~git ~prefix ~dir =
    let open Unix in
    let snd_in, fst_out = pipe () in
    set_close_on_exec snd_in;
    let git = run ~stdout:fst_out (git `LsFiles [ "HEAD" ]) in
    close fst_out;
    clear_close_on_exec snd_in;
    let trd_in, snd_out = pipe () in
    set_close_on_exec trd_in;
    let tar_args = [|
      "tar"; "c";
      "-C"; dir;
      "-T"; "-";
      "--transform"; Lib.sp "s;^;%s/;" prefix;
    |] in
    let tar = run ~stdin:snd_in ~stdout:snd_out tar_args in
    close snd_in;
    close snd_out;
    clear_close_on_exec trd_in;
    let fd = openfile tarball [ O_WRONLY; O_CREAT; O_TRUNC ] 0o644 in
    let gzip = run ~stdin:trd_in ~stdout:fd [| "gzip"; "-1" |] in
    close fd;
    close trd_in;
    git ();
    tar ();
    gzip ()

  let archive ~obj ~tarball ~git ~prefix =
    let open Unix in
    let snd_in, fst_out = pipe () in
    set_close_on_exec snd_in;
    let prefix = sp "--prefix=%s/" prefix in
    let git = run ~stdout:fst_out (git `Archive [ prefix; obj ])  in
    close fst_out;
    clear_close_on_exec snd_in;
    let fd = openfile tarball [ O_WRONLY; O_CREAT; O_TRUNC ] 0o644 in
    let gzip = run ~stdin:snd_in ~stdout:fd [| "gzip"; "-1" |] in
    close snd_in;
    close fd;
    git ();
    gzip ()

  let fetch ~git ~remote =
    let f r = run (git `Fetch r) () in
    match remote with
    | Some remote -> f [ remote ]
    | None -> f []

  let remote_add ~uri ~git ~dir ?remote () =
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
      log dbg "Adding a remote %S to %S at %S.\n%!" remote uri dir;
      try run (git `Remote [ "add"; remote; uri]) () with _ -> ()
    ) remote

  let get { tarball; dir; obj; uri; remote; prefix } =
    let git = git_invoke ~dir in
    match obj with
    | None ->
        tar ~tarball ~git ~dir ~prefix
    | Some obj -> (
        may (fun uri -> remote_add ~uri ~git ~dir ?remote ()) uri;
        fetch ~remote ~git;
        archive ~tarball ~obj ~git ~prefix
    )

  let ts _ =
    "git-sources-are-always-more-recent", infinity
end

module Tarball = struct
  let get (file, sha1) =
    let download ~file =
      run [| "curl"; "-o"; file; (Sys.getenv "MIRROR") ^ "/" ^ file |] ()
    in
    let file_matches_sha1 ~sha1 ~file =
      if sha1 = "" then (
        log dbg "File %S exists and has no SHA1 constraint.\n%!" file;
        true
      )
      else (
        let pipe_read, pipe_write = Unix.pipe () in
        let line = Lib.sp "%s *%s\n" sha1 file in
        let l = String.length line in
        assert (l = Unix.write pipe_write line 0 l);
        Unix.close pipe_write;
        let res = (try
          run ~stdin:pipe_read
            [| "sha1sum"; "--status"; "--check"; "--strict" |] ();
          log dbg "File %S exists and has the right SHA1.\n%!" file;
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
          failwith (Lib.sp "Download of %S (SHA1=%s)." file sha1)
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

  let ts file =
    Unix.handle_unix_error (fun file -> (Unix.lstat file).Unix.st_mtime) file
end

let get =
  let chan_send = Event.new_channel () in
  let chan_ack = Event.new_channel () in
  ignore (Thread.create (fun () ->
    while true do
      Event.sync (Event.send chan_ack (
        try
          let p = Event.sync (Event.receive chan_send) in
          ListLabels.iter p.sources ~f:(fun x -> match x with
            | WB _ -> ()
            | Tarball y -> Tarball.get ~package:p.package y
            | Git.T y -> Git.get y
            | Patch y -> Patch.get y
            | _ -> assert false
          );
          None
        with exn ->
          Some exn
      ))
    done
  ) ());
  (fun l ->
    Event.sync (Event.send chan_send l);
    match Event.sync (Event.receive chan_ack) with
    | None -> ()
    | Some exn -> raise exn)

let timestamp = function
  | Patch patch -> patch, 0.
  | WB file
  | Tarball (file, _) -> file, Tarball.ts file
  | Git.T x -> Git.ts x
  | _ -> assert false

let substitute_variables_sources ~dir ~package ~dict source =
  let sources_dir_ize s = (dir ^/ package) ^/ s in
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


open Lib

module Env = struct
  type t =
    | Prepend of string list
    | Set of string list
    | Clear
    | Keep

  module M = Map.Make (String)

  let get () =
    ArrayLabels.fold_left (Unix.environment ()) ~init:M.empty ~f:(fun m s ->
      let i = String.index s '=' in
      M.add (String.sub s 0 i) (String.sub s (i+1) (String.length s - (i+1))) m
    )

  let to_array env =
    let a = Array.of_list (M.bindings env) in
    Array.map (fun (b, v) -> String.concat "=" [ b; v ]) a

  let process env ts =
    ListLabels.fold_left ts ~init:env ~f:(fun env (name, action) ->
      (* TODO: separator is not always ':' *)
      match action with
      | Prepend l ->
          if M.mem name env then
            let v = M.find name env in
            M.add name (Lib.sp "%s:%s" (String.concat ":" l) v) env
          else
            M.add name (String.concat ":" l) env
      | Set l ->
          M.add name (String.concat ":" l) env
      | Clear ->
          M.remove name env
      | Keep ->
          env
    )
end

module Arch = struct
  type t = {
    triplet : string;
    bits : int;
    strip : string;
    exe_format : string;
  }

  let build =
    let triplet = Sys.getenv "BUILD_TRIPLET" in
    let components = Str.split (Str.regexp "-") triplet in
    let bits =
      match List.hd components with
      | "x86_64" -> 64
      | "i686" | "i586" | "i486" | "i386" -> 32
      | _ -> assert false
    in
    let exe_format =
      match components with
      | [ _; _; "cygwin" ]
      | [ _; _; "msys" ] -> "PE"
      (* The Mac OS X case is listed below but file says
       * "dynamically linked shared library" while the greps in the slackbuilds
       * use "executable|shared object". Therefore, build-only libs won't be
       * stripped but that shouldn't be an issue in practice. *)
      | [ _; "apple"; _ ] -> "Mach-O"
      | _ -> "ELF"
    in
    {
      triplet;
      bits;
      (* don't set --strip-unneeded since it's not standard and will only be
       * used for native/cross toolchains and therefore not redistributed *)
      strip = "strip";
      exe_format;
    }

  let windows_32 = {
    triplet = "i686-w64-mingw32";
    bits = 32;
    strip = "i686-w64-mingw32-strip --strip-unneeded";
    exe_format = "PE";
  }

  let windows_64 = {
    triplet = "x86_64-w64-mingw32";
    bits = 64;
    strip = "x86_64-w64-mingw32-strip --strip-unneeded";
    exe_format = "PE";
  }
end

module Prefix = struct
  type t = {
    yyprefix : string;
    libdir : string;
    nickname : string;
    kind : string;
    build : Arch.t;
    host : Arch.t;
    target : Arch.t;
  }

  let t ~name ~build ~host ~target =
    let basepath =
      try Sys.getenv "YYBASEPATH" with
      | Not_found -> (Sys.getcwd ()) ^/ "opt"
    in
    let kind = (* FIXME *)
      if build = host then
        if build = target then
          "native_toolchain"
        else
          "cross_toolchain"
      else
        "windows"
    in
    let path = basepath ^/ name in
    let libdir =
      path ^/ (if target.Arch.bits = 32 then "lib" else "lib64")
    in
    { build; host; target; nickname = name; kind; yyprefix = path; libdir }
end

module Package = struct
  type source = ..

  type real = {
    dir : string;
    version : string;
    build : int;
    sources : source list;
    outputs : string list;
    prefix : Prefix.t;
  }

  type common = {
    package : string;
    variant : string option;
    dependencies : t list;
    native_deps : string list;
    cross_deps : string list;
    mutable to_build : bool;
    devshell : bool;
  }

  and t =
    | Real of (common * real)
    | Virtual of common
    | Provides of (common * t list)

  let to_name c =
    match c.variant with
    | Some variant -> String.concat ":" [ c.package; variant ]
    | None -> c.package

  let substitute_variables ~dict s =
    let f k =
      try
        Lib.log Lib.dbg "Associating %S in %S.\n%!" k s;
        List.assoc k dict
      with Not_found as exn ->
        Lib.log Lib.cri "Couldn't resolve variable %S in %S.\n%!" k s;
        raise exn
    in
    let b = Buffer.create (String.length s) in
    Buffer.add_substitute b f s;
    let s = Buffer.contents b in
    Lib.log Lib.dbg "Result: %S.\n%!" s;
    s

  let logs_yyoutput ~nickname =
    let rel_path l = List.fold_left (^/) Lib.work_dir l in
    (rel_path [ "logs"; nickname ]), (rel_path [ "packages"; nickname ])

  let c_of = function
    | Real (c, _) -> c
    | Virtual c -> c
    | Provides (c, _) -> c
end

module Builder = struct
  type t = {
    name : string;
    prefix : Prefix.t;
    path : Env.t;
    pkg_config_path : Env.t;
    pkg_config_libdir : Env.t;
    logs : string;
    yyoutput : string;
    tmp : Env.t;
    (* prefix of native tools and libraries *)
    mutable native_prefix : string option;
    (* prefix of the cross toolchain *)
    mutable cross_prefix : string option;
    (* prefix of the cross system *)
    mutable target_prefix : string option;
    cross_name : string option;
    mutable packages : Package.t list;
    default_cross_deps : string list;
    redistributed : bool;
    ld_library_path : Env.t;
    c_path : Env.t;
    library_path : Env.t;
  }

  let env t =
    let module P = Prefix in
    let module A = Arch in
    let build = t.prefix.P.build in
    let host = t.prefix.P.host in
    let target = t.prefix.P.target in
    let libdirsuffix = if host.A.bits = 64 then "64" else "" in
    Env.to_array (Env.process (Env.get ()) [
      "PATH", t.path;
      "LD_LIBRARY_PATH", t.ld_library_path;
      "C_PATH", t.c_path;
      "LIBRARY_PATH", t.library_path;
      "PKG_CONFIG_PATH", t.pkg_config_path; (* FIXME: base on libdir *)
      "PKG_CONFIG_LIBDIR", t.pkg_config_libdir; (* FIXME: base on libdir *)
      "OCAMLFIND_CONF", Env.Set [ t.prefix.P.yyprefix ^ "/etc/findlib.conf" ];
      "ACLOCAL_PATH", Env.Set [ t.prefix.P.yyprefix ^ "/share/aclocal" ];
      "YYPREFIX", Env.Set [ t.prefix.P.yyprefix ];
      (* PREFIX is set right before calling the build script in the same way;
       * better or worse?
       * "PREFIX", Env.Set [ Str.(replace_first (regexp "/") "" prefix) ];
       *)
      "YYOUTPUT", Env.Set [ t.yyoutput ];
      "TMP", t.tmp;
      "LIBDIRSUFFIX", Env.Set [ libdirsuffix ];
      "HOST_EXE_FORMAT", Env.Set [ host.A.exe_format ];
      "TARGET_EXE_FORMAT", Env.Set [ target.A.exe_format ];
      "BUILD_EXE_FORMAT", Env.Set [ build.A.exe_format ];
      "HOST_STRIP", Env.Set [ host.A.strip ];
      "TARGET_STRIP", Env.Set [ target.A.strip ];
      "BUILD_STRIP", Env.Set [ build.A.strip ];
      "HOST_TRIPLET", Env.Set [ host.A.triplet ];
      "TARGET_TRIPLET", Env.Set [ target.A.triplet ];
      "BUILD_TRIPLET", Env.Set [ build.A.triplet ];
      "YYPREFIX_CROSS",
        (match t.cross_prefix with Some p -> Env.Set [ p ] | None -> Env.Keep);
      "YYPREFIX_NATIVE",
        (match t.native_prefix with Some p -> Env.Set [ p ] | None -> Env.Keep);
      "YYPREFIX_TARGET",
        (match t.target_prefix with Some p -> Env.Set [ p ] | None -> Env.Keep);
      "YYLOWCOMPRESS", (if t.redistributed then Env.Keep else Env.Set [ "1" ]);
    ])

  let shall_build builder_name =
    let h = Hashtbl.create 200 in
    ListLabels.iter (set_of_env (String.uppercase builder_name)) ~f:(fun e ->
      match Str.split (Str.regexp ":") e with
      | [ n ] -> Hashtbl.add h (n, None, false) true
      | [ n; "devshell" ] -> Hashtbl.add h (n, None, true) true
      | [ n; v ] -> Hashtbl.add h (n, Some v, false) true
      | [ n; v; "devshell" ] -> Hashtbl.add h (n, Some v, true) true
      | [ ] -> ()
      | _ -> assert false
    );
    fun p ->
      let c = Package.c_of p in
      Hashtbl.mem h Package.(c.package, c.variant, c.devshell)
end

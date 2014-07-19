open Types

let lists = ref []

let add
    ~push ~shall_build
    (package, variant)
    ~dir ~dependencies ~version ~build ~sources ~outputs
  =
  let rec colorize p =
    if not p.to_build && shall_build p then (
      p.to_build <- true;
      List.iter colorize p.dependencies
    )
  in
  let add_aux p = colorize p; push p; p in
  add_aux {
    package; variant; dir; dependencies;
    version; build;
    sources; outputs;
    to_build = false;
  }

let register ~name =
  let shall_build =
    let l = try Sys.getenv (String.uppercase name) with Not_found -> "" in
    if l = "all" then
      fun _ -> true
    else
      let h = Hashtbl.create 200 in
      ListLabels.iter (Str.split (Str.regexp ",") l) ~f:(fun e ->
        match Str.split (Str.regexp ":") e with
        | [ n; v ] -> Hashtbl.add h (n, Some v) true
        | [ n ] -> Hashtbl.add h (n, None) true
        | _ -> assert false
      );
      fun p -> Hashtbl.mem h (p.package, p.variant)
  in
  let q = Queue.create () in
  lists := !lists @ [ name, q ];
  add ~push:(fun p -> Queue.push p q) ~shall_build


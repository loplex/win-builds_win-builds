type x = {
  id : string;
  mutable s : string;
}

let xs = ref []

let write ~flush x s =
  let open Printf in
  let open String in
  (* TODO: don't hardcode 80 columns *)
  let width = (81 / (List.length !xs)) - 1 in
  x.s <- s;
  let line = String.concat " " (List.rev_map (fun { id; s } ->
    let l = sprintf "%-*s" width (sprintf "%s-%s" id s) in
    String.sub l 0 (min width (String.length l))
    )
  !xs) in
  printf "\r%s%s%!" line (if flush then "\n" else "")

let create id =
  let x = { id; s = "" } in
  xs := x :: !xs;
  x

let release x =
  xs := List.filter ((<>) x) !xs

let re_use = Str.regexp "[ ]*#use \"\\(.*\\)\""
let re_variant = Str.regexp "wb-\\(.*\\)"
let re_extras_hook = Str.regexp "[ ]*#extras"
let re_extras = Str.regexp ","

let extras_of_env basename =
  let name = (String.uppercase basename) ^ "_EXTRAS" in
  try
    Str.split re_extras (Sys.getenv name)
  with
    Not_found -> []

let rec use ?(toplevel = false) ?(extras = []) file =
  let lines = ref 0 in
  let use_wb_ml s =
    let file' = Str.matched_group 1 s in
    use file';
    Printf.printf "# %d %S\n" !lines file
  in
  let ic = open_in_bin file in
  let basename = Filename.chop_extension (Filename.basename file) in
  (if toplevel then (
    let modname = String.capitalize basename in
    Printf.printf "module %s = struct\n" (String.capitalize modname)
  )
  else (
    let dir = Filename.dirname file in
    Printf.printf "# 1 \"%s [header]\"\n" file;
    Printf.printf "let dir = %S in\n" (Filename.dirname dir);
    Printf.printf "let name = %S in\n" (Filename.basename dir);
    (if Str.string_match re_variant basename 0 then (
      Printf.printf "let variant = Some %S in\n" (Str.matched_group 1 basename);
    )
    else (
      Printf.printf "let variant = None in\n";
    ));
  ));
  Printf.printf "# 1 %S\n" file;
  (try
    while true do
      let s = input_line ic in
      incr lines;
      if Str.string_match re_use s 0 then
        use_wb_ml s
      else
        if Str.string_match re_extras_hook s 0 then
          List.iter use (extras_of_env basename)
        else
          Printf.printf "%s\n" s
    done
  with End_of_file -> ());
  (if toplevel then
    Printf.printf "end\n"
  else (
    Printf.printf "# 1 \"%s [trailer]\"\n" file;
    Printf.printf "let dir = Lib.Poison in\n";
    Printf.printf "let name = Lib.Poison in\n";
    Printf.printf "ignore dir; ignore name;\n";
  ));
  close_in ic
;;

use ~toplevel:true "build/lib.ml";;
use ~toplevel:true "build/statusline.ml";;
use ~toplevel:true "build/config.ml";;
use ~toplevel:true "build/sources.ml";;
use ~toplevel:true "build/worker.ml";;
use ~toplevel:true "build/builders.ml";;
use ~toplevel:true "build/windows.ml";;
use ~toplevel:true "build/cross_toolchain.ml";;
use ~toplevel:true "build/native_toolchain.ml";;
use ~toplevel:true "build/build.ml";;


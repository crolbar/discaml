open Unix
open Config

let print_cool_msg msg = if !dbg then Printf.printf "\x1b[34m%s\x1b[m\n%!" msg
let print_err_msg msg = if !dbg then Printf.printf "\x1b[31m%s\x1b[m\n%!" msg

let connect sock socketPath =
  try Unix.connect sock (ADDR_UNIX !socketPath) with
  | Unix.Unix_error (err, f, _) ->
    print_err_msg
      ("error: "
       ^ Unix.error_message err
       ^ " in function: "
       ^ f
       ^ " with sock path: "
       ^ !socketPath)
;;

let write sock opcode buf =
  let buf_size = Bytes.length buf in
  let header = Bytes.create 8 in
  ignore (Bytes.set_int32_le header 0 (Int32.of_int opcode));
  ignore (Bytes.set_int32_le header 4 (Int32.of_int buf_size));
  let full = Bytes.cat header buf in
  Unix.write sock full 0 (Bytes.length full)
;;

let read sock : string =
  let header = Bytes.create 8 in
  ignore (Unix.read sock header 0 8);
  let size = Int32.to_int (Bytes.get_int32_le header 4) in
  let buf = Bytes.create size in
  ignore (Unix.read sock buf 0 size);
  Bytes.to_string buf
;;

let print_cool_back_msg discord_msg =
  if !dbg then Printf.printf "\x1b[32mgot back: %s\x1b[m\n%!" discord_msg
;;

let print_cool_write_msg n msg =
  if !dbg then Printf.printf "\x1b[36mwrote(%o): %s\x1b[m\n%!" n msg
;;

let run cmd =
  let inp = Unix.open_process_in cmd in
  let r = In_channel.input_all inp in
  In_channel.close inp;
  r
;;

exception Return of int

let parse_script_out out =
  let f =
    fun pair ->
    let split = String.split_on_char '=' pair in
    if List.length split != 2
    then (
      print_err_msg ("error split on '=' with cmd output: " ^ out);
      raise (Return 1));
    let key = String.trim (List.nth split 0)
    and v = String.trim (List.nth split 1) in
    if String.equal key "name"
    then (
      activity.name := v;
      print_cool_msg ("set name to: " ^ v))
    else if String.equal key "state"
    then (
      activity.state := v;
      print_cool_msg ("set state to: " ^ v))
    else if String.equal key "details"
    then (
      activity.details := v;
      print_cool_msg ("set details to: " ^ v))
    else if String.equal key "t"
    then (
      activity.t := int_of_string v;
      print_cool_msg ("set t to: " ^ v))
    else if String.equal key "started"
    then (
      activity.started := int_of_string v;
      print_cool_msg ("set started to: " ^ v))
    else if String.equal key "image"
    then (
      activity.image := v;
      print_cool_msg ("set image to: " ^ v))
    else
      print_err_msg
        ("got unknown key from script: `"
         ^ key
         ^ "` with value: `"
         ^ v
         ^ "` Supported are name,state,details,t,started")
  and key_val_pairs = String.split_on_char ';' out in
  try List.iter f key_val_pairs with
  | Return _ -> ()
;;

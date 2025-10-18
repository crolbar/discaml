open Unix
open Config

let connect sock socketPath = Unix.connect sock (ADDR_UNIX !socketPath)

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

open Unix

let sock = socket PF_UNIX SOCK_STREAM 0
let socketPath = "/run/user/1000/discord-ipc-0"
let connect () = Unix.connect sock (ADDR_UNIX socketPath)
let dbg = true

let msg =
  {|{"cmd":"SET_ACTIVITY","args":{"activity":{"details":"what?","name":"","state":"hello?","type":0},"pid":"9999"},"evt":null,"nonce":"-"}|}

let init_msg = {|{"client_id": "1219918645770059796", "v": 1}|}

let write opcode buf =
  let buf_size = Bytes.length buf in
  let header = Bytes.create 8 in
  ignore (Bytes.set_int32_le header 0 (Int32.of_int opcode));
  ignore (Bytes.set_int32_le header 4 (Int32.of_int buf_size));
  let full = Bytes.cat header buf in
  Unix.write sock full 0 (Bytes.length full)

let read () : string =
  let size = 428 in
  let buf = Bytes.create size in
  ignore (Unix.read sock buf 0 size);
  Bytes.to_string buf

let print_cool_back_msg discord_msg =
  if dbg then Printf.printf "\x1b[32mgot back: %s\x1b[m\n%!" discord_msg

let print_cool_write_msg n msg =
  if dbg then Printf.printf "\x1b[36mwrote(%o): %s\x1b[m\n%!" n msg

let rec loop =
 fun () ->
  let n = write 1 (Bytes.of_string msg) in
  print_cool_write_msg n msg;

  let discord_msg = read () in
  print_cool_back_msg discord_msg;

  sleep 1;
  loop ()
;;

connect ();;

let n = write 0 (Bytes.of_string init_msg) in
print_cool_write_msg n msg
;;

let discord_msg = read () in
print_cool_back_msg discord_msg
;;

loop ()

open Unix
open Util
open Config;;

Arg.parse
  [
    "-id", Arg.Set_int client_id, "client id";
    "-n", Arg.Set_string activity.name, "set name";
    "-d", Arg.Set_string activity.details, "set details";
    "-s", Arg.Set_string activity.state, "set state";
    ( "-t",
      Arg.Set_int activity.t,
      "set type \
       (https://discord.com:2053/developers/docs/events/gateway-events#activity-object-activity-types)"
    );
    "-start", Arg.Set_int activity.started, "set started unix milis timestamp";
    ( "-tick",
      Arg.Set_int sleep_seconds,
      "seconds to wait between sending activity to discord" );
    "-debug", Arg.Set dbg, "debug logs";
    ( "-script",
      Arg.Set_string tick_script,
      "script that outputs name,details,state and be called each tick (output \
       format is `name=somename;details=somedetails;state=somestatus`)" );
    ( "-sock",
      Arg.Set_string socketPath,
      "set discord ipc unix socket (or just pass `$(ss -lx | grep -o '[^ \
       ]*discord[^ ]*' | head -n 1)`)" );
  ]
  (fun _ -> ())
  "discaml cli arguments:"

let sock = socket PF_UNIX SOCK_STREAM 0

let get_msg () : string =
  let opt (key : string) (s : string) : string =
    if String.length s != 0 then Printf.sprintf {|"%s": "%s",|} key s else ""
  and opt_cond (key : string) (cond : bool) (s : string) : string =
    if cond then Printf.sprintf {|"%s": %s,|} key s else ""
  in
  {|{"cmd":"SET_ACTIVITY","args":{"activity":{|}
  ^ opt "name" !(activity.name)
  ^ opt "details" !(activity.details)
  ^ opt "state" !(activity.state)
  ^ opt_cond
      "assets"
      (String.length !(activity.image) != 0)
      (Printf.sprintf {|{"large_image":"%s"}|} !(activity.image))
  ^ Printf.sprintf {|"type":%d,|} !(activity.t)
  ^ Printf.sprintf {|"timestamps":{"start":%d}|} !(activity.started)
  ^ {|},"pid":"9999"},"nonce":"-"}|}
;;

let init_msg = Printf.sprintf {|{"client_id": "%d", "v": 1}|} !client_id

let init_client () =
  let n = write sock 0 (Bytes.of_string init_msg) in
  print_cool_write_msg n init_msg;
  let discord_msg = read sock in
  print_cool_back_msg discord_msg;
  ()
;;

let rec loop =
  fun () ->
  if String.length !tick_script > 0
  then (
    let out = run !tick_script in
    parse_script_out out);
  let msg = get_msg () in
  let n = write sock 1 (Bytes.of_string msg) in
  print_cool_write_msg n msg;
  let discord_msg = read sock in
  print_cool_back_msg discord_msg;
  sleep !sleep_seconds;
  loop ()
;;

connect sock socketPath;;
init_client ();;
loop ()

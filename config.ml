let dbg = ref false
let socketPath = ref "/run/user/1000/discord-ipc-0"
let client_id = ref 1429152346092470332
let sleep_seconds = ref 5

type activity = {
  name : string ref;
  details : string ref;
  state : string ref;
  t : int ref;
  started : int ref;
}

let activity : activity =
  {
    (* name = String.make 30000 '_'; *)
    name = ref "_";
    details = ref "";
    state = ref "";
    t = ref 3;
    started = ref (int_of_float (Unix.gettimeofday () *. 1000.0));
  }
;;

let dbg = ref false
let socketPath = ref "/run/user/1000/discord-ipc-0"
let client_id = ref 1429152346092470332
let sleep_seconds = ref 5
let tick_script = ref ""

type activity = {
  name : string ref;
  details : string ref;
  state : string ref;
  t : int ref;
  started : int ref;
  image : string ref;
}

let activity : activity =
  {
    name = ref "";
    details = ref "";
    state = ref "";
    t = ref 0;
    started = ref (int_of_float (Unix.gettimeofday () *. 1000.0));
    image = ref "";
  }
;;

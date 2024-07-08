open Unix

let server_socket = ref None
let pid = getpid ()

let random_number l r = Random.self_init (); l + Random.int r

let close_server_socket () =
  try
    match !server_socket with
    | Some sock ->
        close sock;
        (* Printf.printf "Server socket closed\n"; *)
        server_socket := None
    | None ->
        Printf.printf "No server socket to close\n"
  with e -> ()

let send_to_server message =
  try
    match !server_socket with
    | Some sock ->
      let message_bytes = Bytes.of_string message in
      let _ = send sock message_bytes 0 (Bytes.length message_bytes) [] in ()
      (* Printf.printf "Sent %d bytes to the server\n" bytes_sent *)
    | None -> 
        Printf.printf "No server socket to send\n"
    with e ->
    close_server_socket ();
    exit 0
    

let listen_messages sock =
  let in_chan = in_channel_of_descr sock in
  while true do
    let ask = input_line in_chan in
    let length = String.length ask in
    let ack = "Response from child PID: " ^ string_of_int pid ^ ". Got " ^ string_of_int length ^ " bytes." in
    send_to_server ack
  done

let lister_server () =
  try
    match !server_socket with
    | Some sock -> listen_messages sock
    | None -> Printf.printf "No server socket to send\n"
  with e -> ()

let connect_to_server server_ip server_port =
  let sock = socket PF_INET SOCK_STREAM 0 in
  let server_addr = inet_addr_of_string server_ip in
  let server_sockaddr = ADDR_INET (server_addr, server_port) in
  
  connect sock server_sockaddr;
  server_socket := Some sock

let try_connect_to_server server_ip server_port =
  while !server_socket = None do
    try
      connect_to_server server_ip server_port;
	with e ->
	  Printf.printf "Reconnect after 3 secs\n%!";
	  sleep 3
  done

let keep_alive () = 
  while true do
    let sec = random_number 5 20 in sleep sec;
    let alive = "Alive from PID: " ^ string_of_int pid in
    send_to_server alive
  done

let shutdown () = 
  let x = random_number 60 120 in sleep x;
  close_server_socket ();
  (* Printf.printf "Goodbuy \n%!"; *)
  exit 0

let main () =
  let host = Sys.argv.(1) in
  let port = int_of_string Sys.argv.(2) in
  try_connect_to_server host port;

  let listen_server_thread = Thread.create lister_server () in
  let keep_alive_thread = Thread.create keep_alive () in
  let shutdown_thread = Thread.create shutdown () in

  Thread.join listen_server_thread;
  Thread.join keep_alive_thread;
  Thread.join shutdown_thread

let () = main ()

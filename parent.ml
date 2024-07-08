open Unix

let list_of_child_pids = ref []
let list_of_child_sockets = ref []

let number_of_child_processes = ref 1
let server_host = ref "127.0.0.1"
let server_port = ref 54321

let read_params () = 
   Arg.parse 
    [
      ("-n", Arg.Set_int number_of_child_processes, "Set number of child processes. Should be >= 1 and <= 50. Default 1");
      ("-h", Arg.Set_string server_host, "Set host to be listen on. Default 127.0.0.1");
      ("-p", Arg.Set_int server_port, "Set port to be listen on. Default 54321")
    ] 
    (fun s -> ()) 
    "parent -n <number_of_child_processes> -h <server_host> -p <server_port>"

let format_current_time () =
  let time = gmtime (time ()) in
  let year = 1900 + time.tm_year in
  let month = time.tm_mon + 1 in
  let day = time.tm_mday in
  let hour = time.tm_hour in
  let min = time.tm_min in
  let sec = time.tm_sec in
  let tm_usec = (gettimeofday () -. floor (gettimeofday ())) *. 1000.0 in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ"
    year month day hour min sec (int_of_float tm_usec)

let info message =
  let prefix = format_current_time () ^ "  INFO -- " in
  let channel = open_out_gen [Open_append; Open_creat] 0o666 "log.txt" in
  try
    Printf.fprintf channel "%s%s\n" prefix message;
    flush channel;
    close_out channel
  with e ->
    close_out channel

let create_child_process _ =
  let child = "./child" in
  let args = [| child; (!server_host); string_of_int (!server_port) |] in
  let pid = create_process child args stdin stdout stderr in
  list_of_child_pids := !list_of_child_pids @ [pid];
  let log = "Child process created. PID: " ^ string_of_int pid in info log

let remove_socket target =
  list_of_child_sockets := 
  List.fold_right (fun x acc -> if x = target then acc else x :: acc) !list_of_child_sockets []

let handle_client client_sock =
  let buffer = Bytes.create 1024 in
  try
    while true do
      let bytes_read = read client_sock buffer 0 1024 in 
       if bytes_read = 0 then raise Exit;
      let received_data = Bytes.sub_string buffer 0 bytes_read in info received_data;
      ignore (write client_sock (Bytes.of_string received_data) 0 bytes_read)
    done
  with
  | Exit -> 
    info "Child disconnected.";
    remove_socket client_sock;
    create_child_process ()
  | e -> 
    info "Child disconnected.";
    remove_socket client_sock;
    create_child_process ()

let socket_handler addr port = 
    let server_sock = socket PF_INET SOCK_STREAM 0 in
    let localhost = inet_addr_of_string addr in
    let server_addr = ADDR_INET (localhost, port) in

    bind server_sock server_addr;
    listen server_sock 100;
    let log = Printf.sprintf "Server listening on port %i." port in info log;

    while true do
      let (client_sock, client_addr) = accept server_sock in
      match client_addr with
      | ADDR_INET (client_ip, client_port) ->
          let log = Printf.sprintf "Child connected from %s:%d" (string_of_inet_addr client_ip) client_port in info log;
          list_of_child_sockets := !list_of_child_sockets @ [client_sock];
          let _ = Thread.create handle_client client_sock in ()
      | _ -> ()
    done

let start_listen_tcp_socket addr port = 
  let _ = Thread.create (fun () -> socket_handler addr port) () in ()

let send_message_to_child socket message =
  try
    let enchanced = message ^ "\n" in
    let bytes = Bytes.of_string enchanced in
    let len = Bytes.length bytes in
    let _ = send socket bytes 0 len [] in ()
  with
  | e -> let log = Printf.sprintf "Error: %s\n%!" (Printexc.to_string e) in info log

let send_message_to_children message = 
  for i = 0 to (List.length !list_of_child_sockets) - 1 do
    send_message_to_child (List.nth !list_of_child_sockets i) message
  done

let main () =
  read_params ();
  start_listen_tcp_socket !server_host !server_port;

  for i = 1 to !number_of_child_processes do
    create_child_process ();
  done;

  while true do
    Printf.printf "Enter a message: ";
    read_line() |> send_message_to_children;
  done

let () = main ()

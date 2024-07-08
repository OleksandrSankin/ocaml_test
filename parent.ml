open Unix

let list_of_child_pids = ref []
let list_of_child_sockets = ref []

let number_of_child_processes () = 
   let num = ref 0 in
   Arg.parse 
    [("-n", Arg.Set_int num, "Set number of child processes")] 
    (fun s -> ()) 
    "parent -n <number_of_child_processes>";
   num

let remove_socket target =
  list_of_child_sockets := 
  List.fold_right (fun x acc -> if x = target then acc else x :: acc) !list_of_child_sockets []

let handle_client client_sock =
  let buffer = Bytes.create 1024 in
  try
    while true do
      let bytes_read = read client_sock buffer 0 1024 in
        if bytes_read = 0 then raise Exit;
      let received_data = Bytes.sub_string buffer 0 bytes_read in
        Printf.printf "Received: %s\n%!" received_data;
      ignore (write client_sock (Bytes.of_string received_data) 0 bytes_read)
    done
  with
  | Exit -> 
    Printf.printf "Client disconnected\n%!";
    remove_socket client_sock
  | e -> Printf.printf "Error: %s\n%!" (Printexc.to_string e)

let socket_handler addr port = 
    let server_sock = socket PF_INET SOCK_STREAM 0 in
    let localhost = inet_addr_of_string addr in
    let server_addr = ADDR_INET (localhost, port) in

    bind server_sock server_addr;
    listen server_sock 100;
    Printf.printf "Server listening on port %i\n%!" port;

    while true do
      let (client_sock, client_addr) = accept server_sock in
      match client_addr with
      | ADDR_INET (client_ip, client_port) ->
          Printf.printf "Client connected from %s:%d\n%!" (string_of_inet_addr client_ip) client_port;
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
  | e -> Printf.printf "Error: %s\n%!" (Printexc.to_string e)

let send_message_to_children message = 
  for i = 0 to (List.length !list_of_child_sockets) - 1 do
    send_message_to_child (List.nth !list_of_child_sockets i) message
  done

let log message =
  let channel = open_out_gen [Open_append; Open_creat] 0o666 "log.txt" in
  try
    Printf.fprintf channel "%s\n" message;
    flush channel;
    close_out channel
  with e ->
    close_out channel;
    raise e

let create_child_process _ =
  let child_program = "./child" in
  let child_args = [| child_program; "127.0.0.1"; "54321" |] in
  let pid = create_process child_program child_args stdin stdout stderr in
  let _, status = waitpid [] pid in
  list_of_child_pids := !list_of_child_pids @ [pid];
  match status with
  | WEXITED code -> Printf.printf "Child exited with code %d\n" code
  | WSIGNALED signal -> Printf.printf "Child killed by signal %d\n" signal
  | WSTOPPED signal -> Printf.printf "Child stopped by signal %d\n" signal

let main () =

  start_listen_tcp_socket "127.0.0.1" 54321;
  let n = number_of_child_processes() in
  for i = 1 to !n do
    Printf.printf "AAAA: ";
    create_child_process ();
    Printf.printf "BBBB: ";
  done;

  while true do
    Printf.printf "Enter a message: ";
    read_line() |> send_message_to_children;
  done

let () = main ()

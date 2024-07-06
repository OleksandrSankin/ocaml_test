open Unix

let number_of_child_processes = ref 0

let read_number_of_child_processes () = 
   Arg.parse 
    [("-n", Arg.Set_int number_of_child_processes, "Set number of child processes")] 
    (fun s -> ()) 
    "parent -n <number_of_child_processes>"

let create_child_processes num = 
  for i = 1 to num do
    Printf.printf "Child process created\n%!"
  done

let handle_client client_sock =
  let buffer = Bytes.create 1024 in
  try
    while true do
      let bytes_read = read client_sock buffer 0 1024 in
      if bytes_read = 0 then raise Exit; (* Client closed connection *)
      let received_data = Bytes.sub_string buffer 0 bytes_read in
      Printf.printf "Received: %s\n%!" received_data;
      ignore (write client_sock (Bytes.of_string received_data) 0 bytes_read)
    done
  with
  | Exit -> Printf.printf "Client disconnected\n%!"
  | e -> Printf.printf "Error: %s\n%!" (Printexc.to_string e)

let open_tcp_socket port = 
  let server_sock = socket PF_INET SOCK_STREAM 0 in
  let server_addr = ADDR_INET (inet_addr_any, port) in

  bind server_sock server_addr;
  listen server_sock 10;
  Printf.printf "Server listening on port %i\n%!" port;

  while true do
    let (client_sock, client_addr) = accept server_sock in
    match client_addr with
    | ADDR_INET (client_ip, client_port) ->
        Printf.printf "Client connected from %s:%d\n%!"
          (string_of_inet_addr client_ip) client_port;
        let _ = Thread.create handle_client client_sock in
        ()
    | _ -> ()
  done

let log message =
  let channel = open_out_gen [Open_append; Open_creat] 0o666 "log.txt" in
  try
    Printf.fprintf channel "%s\n" message;
(*     output_string channel content;
    output_string channel "\n"; *)
    flush channel;
    close_out channel
  with e ->
    close_out channel;
    raise e

let create_child_process _ =
  match fork () with
  | 0 ->
      (* This is the child process *)
      Printf.printf "In child process. PID: %d\n%!" (getpid ());
      (* Replace the child process with a new program *)
      execv "/bin/echo" [| "echo"; "Hello from the child process!" |]
  | pid ->
      (* This is the parent process *)
      Printf.printf "In parent process. Child PID: %d\n%!" pid;
      (* Wait for the child process to finish *)
      let (_, status) = waitpid [] pid in
      (match status with
      | WEXITED code -> Printf.printf "Child process exited with code %d\n%!" code
      | WSIGNALED signal -> Printf.printf "Child process was killed by signal %d\n%!" signal
      | WSTOPPED signal -> Printf.printf "Child process was stopped by signal %d\n%!" signal)

let () =

  log "sdlkfjsdlkfjsdlfkjsldfkj";
  log "sdlkfjsdlkfjsdlfkjsldfkj";
  log "sdlkfjsdlkfjsdlfkjsldfkj";
  log "sdlkfjsdlkfjsdlfkjsldfkj";
  log "sdlkfjsdlkfjsdlfkjsldfkj";
  log "sdlkfjsdlkfjsdlfkjsldfkj";
  
  (* let _ = Thread.create (fun () -> open_tcp_socket 54321) () in *)

  (* Thread.join thread1; *)
  (* Thread.create (fun () -> (open_tcp_socket 54321)) (); *)
  (* Printf.printf "Both threads have finished\n%!"; *)

  (* create_child_process; *)
  (* read_number_of_child_processes(); *)
  (* open_tcp_socket 54321; *)
  (* create_child_processes !number_of_child_processes; *)
  (* Printf.printf  "Number is %d\n%!" !number_of_child_processes *)
  while true do
    Printf.printf "Enter: ";
    read_line() |> Printf.printf "You entered: %s\n"
  done


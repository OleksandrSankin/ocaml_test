
let number_of_child_processes = ref 0

let read_number_of_child_processes () = 
   Arg.parse 
    [("-n", Arg.Set_int number_of_child_processes, "Set number of child processes")] 
    (fun s -> ()) 
    "parent -n <number_of_child_processes>"

let main () =
  read_number_of_child_processes();
  Printf.printf  "Number is %d\n%!" !number_of_child_processes

let () = main ()

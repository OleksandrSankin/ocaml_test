
#### How to build:
`ocamlfind ocamlc -package lwt,lwt.unix -linkpkg -thread -o parent parent.ml`\
`ocamlfind ocamlc -package lwt,lwt.unix -linkpkg -thread -o child child.ml`

#### How to run:

With default parameters: number of childs = 1, server host = 127.0.0.1, server port = 54321:

`./parent` 

Or specify directly:

`./parent -n 10 -h 127.0.0.1 -p 54321`

#### Logs example:

````
2024-07-08T07:50:52.945Z  INFO -- Child process created. PID: 11674
2024-07-08T07:50:52.945Z  INFO -- Server listening on port 54321.
2024-07-08T07:50:52.953Z  INFO -- Child connected from 127.0.0.1:60148
2024-07-08T07:50:59.954Z  INFO -- Alive from PID: 11674
2024-07-08T07:51:04.960Z  INFO -- Alive from PID: 11674
2024-07-08T07:51:06.225Z  INFO -- Response from child PID: 11674. Got 45 bytes.
2024-07-08T07:51:08.318Z  INFO -- Response from child PID: 11674. Got 49 bytes.
2024-07-08T07:51:15.623Z  INFO -- Response from child PID: 11674. Got 51 bytes.
2024-07-08T07:51:16.450Z  INFO -- Response from child PID: 11674. Got 52 bytes.
2024-07-08T07:51:17.277Z  INFO -- Response from child PID: 11674. Got 52 bytes.
2024-07-08T07:51:26.965Z  INFO -- Alive from PID: 11674
2024-07-08T07:51:32.968Z  INFO -- Alive from PID: 11674
2024-07-08T07:51:49.974Z  INFO -- Alive from PID: 11674
2024-07-08T07:51:55.979Z  INFO -- Alive from PID: 11674
2024-07-08T07:52:15.985Z  INFO -- Alive from PID: 11674
2024-07-08T07:52:28.987Z  INFO -- Alive from PID: 11674
2024-07-08T07:52:34.988Z  INFO -- Alive from PID: 11674
2024-07-08T07:52:45.188Z  INFO -- Response from child PID: 11674. Got 195 bytes.
2024-07-08T07:52:50.991Z  INFO -- Alive from PID: 11674
2024-07-08T07:53:05.955Z  INFO -- Child disconnected.
2024-07-08T07:53:05.957Z  INFO -- Child process created. PID: 11816
2024-07-08T07:53:05.969Z  INFO -- Child connected from 127.0.0.1:60159
2024-07-08T07:53:16.971Z  INFO -- Alive from PID: 11816
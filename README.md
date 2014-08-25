# Cure

A small library that interfaces Elixir-code with C-programs using Erlang/Elixir Ports. Provides Mix tasks to kickstart the development process.

## Example

The following example loads a program called "program" which is located in the ./c_src/ directory.

```elixir
# Open the Port to the C-program:
{:ok, server_pid} = Cure.load "./c_src/program" 

# Sending and receiving data:
# Option 1:
server_pid |> Cure.send_data("Testing 1, 2, 3!", fn(data) ->
    # Process the received data here.
    IO.inspect data
end)

# Option 2:
server_pid |> Cure.send_data("More data!")
receive do
  {:cure_data, data} ->
    # Process the received data here.
    IO.inspect data
end

# Close the C-program:
server_pid |> Cure.stop
```

By default, Cure starts a supervisor which supervises all of its children (a child in this case is a GenServer that communicates with a C-program). A child is added to the supervision tree with Cure.load(program_name). If you don't want this behaviour, you can also directly start a server with one of the following lines of code:

```elixir
# Option 1:
{:ok, server_pid} = Cure.Server.start_link "program_name"

# Option 2:
{:ok, server_pid} = Cure.Server.start "program_name"
```

## Getting started

### Add the Cure dependency to your mix.exs file:
```elixir
def deps do
	[{:cure, "~> 0.0.1"}]
end
```
### Fetch & compile dependencies
```
mix deps.get
mix deps.compile
```

### Start developing in C

- Generate the necessary base files to communicate between C and Elixir:
```
mix cure.bootstrap
```

- Compile your C-code (needed after each modification of your C-code):
```
mix cure.make
```

## C-code

C-code is currently placed in the c_src directory of your application.
It can interface with Elixir-code based on 2 important functions:

1. read_msg to read data coming from Elixir;
2. send_msg to send data to Elixir.

- These helper-functions interface with Elixir by sending/receiving data via stdin or stdout. (Right now it's only possible to send messages up to 64KiB.)
- To be able to use the send and receive functions, you need to add the following include:
```C
#include <elixir_comm.h>
```

- The code for these functions is mostly based on the following [link](http://www.erlang.org/doc/tutorial/c_port.html#id57564).

## Makefile

The command "mix cure.bootstrap" generates a basic Makefile (in ./c_src/) that handles the compilation of all your C-code. This file is only generated if it doesn't exist yet so it's safe to add modifications for when your C-files need extra includes to compile properly.

The command "mix cure.make" uses the Makefile to compile all your C-code.

## More information regarding Ports

- [Erlang documentation](http://www.erlang.org/doc/tutorial/c_port.html)
- [Elixir](http://elixir-lang.org/docs/stable/elixir/Port.html)

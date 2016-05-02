# Cure

A small library that interfaces Elixir-code with C/C++ programs using Erlang/Elixir Ports. Provides Mix tasks to kickstart the development process.

## Example

The following example loads a program called "program" which is located in the ./c_src/ directory of your project.

```elixir
# Open the Port to the C/C++ program:
{:ok, server} = Cure.load "./c_src/program"

# Depending on the kind of communication you need, there are several modes for
# sending and receiving messages:

# Option 1 (once, asynchronous):
# Useful for messages that generate a single response

# without callback function
server |> Cure.send_data "any binary can be transmitted to the C/C++ side!", :once
receive do
  {:cure_data, response} ->
    # Process response here..
end

# with callback function
server |> Cure.send_data <<1, 2, 3>>, :once, fn(response) ->
  # Process response here..
end


# Option 2 (noreply, asynchronous):
# Useful if you don't need a response from the C/C++ side or if you are
# already subscribed to the Cure process.
server |> Cure.send_data "more data..", :noreply


# Option 3 (permanent, asynchronous)
# Useful when you want to keep processing responses after you send an initial message
# (NOTE: After this function is used once, you can use :noreply and
# still keep getting responses)

# without callback function
server |> Cure.send_data "abcdef", :permanent
receive do
  {:cure_data, msg} ->
    # Process response here...
end

# with callback function
server |> Cure.send_data "...", :permanent, fn(response) ->
  # Process response here..
end


# Option 4 (synchronous):
# (a timeout can also be added as last argument)
result1 = server |> Cure.send_data "testdata", :sync
server |> Cure.send_data <<1,2,3>>, :sync, fn(response) ->
    IO.inspect response
end


# Close the program:
server |> Cure.stop # stops the supervised server
```

By default, Cure starts a supervisor which supervises all of its children (a child in this case is a GenServer that communicates with a C/C++ program). A child is added to the supervision tree with Cure.load(program_name). If you don't want this behaviour, you can also directly start a server with one of the following lines of code:

```elixir
# Option 1:
{:ok, server} = Cure.Server.start_link "program_name"

# Option 2:
{:ok, server} = Cure.Server.start "program_name"

# Stopping the server:
:ok = Cure.Server.stop(server)
```

A process can also (un)subscribe to responses coming from the C/C++ side using the following functions:

```elixir
# Option 1: receives responses as {:cure_data, ...}
server |> Cure.subscribe
server |> Cure.unsubscribe

# Option 2: passes every response to a function that processes it
fun = fn(response) -> IO.inspect response end
server |> Cure.subscribe fun
server |> Cure.unsubscribe fun
```

Examples that use Cure can be found at the following links:

- [Subtitlex](https://github.com/Primordus/Subtitlex)

## Getting started

### Add the Cure dependency to your mix.exs file:
```elixir
def deps do
	[{:cure, "~> 0.4.0"}]
end
```

If you're using Cure with a Phoenix application, add Cure to your list of
applications:
```elixir
def application do
  [mod: {YourApp, []},
   applications: [:phoenix, :phoenix_html, :cowboy, :logger, :gettext,
                  :phoenix_ecto, :postgrex, :cure]]
end
```
### Fetch & compile dependencies
```
mix deps.get
mix deps.compile
```

### Start developing in C/C++

- Generate the necessary base files to communicate between C/C++ and Elixir:
```
mix cure.bootstrap
```

- Compile your C/C++ code (needed after each modification of your code)
```
mix compile.cure
```

- If you have dependencies that also use Cure:
```
mix compile.cure.deps
```

Another option is to add the last 2 tasks to your mix.exs to compile all code
automatically when you type mix.compile:

```elixir
def project do
  [...,
    compilers: Mix.compilers ++ [:cure, :"cure.deps"],
    ...]
end
```

## C/C++ code

C/C++ code is currently placed in the c_src directory of your application.
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

The command "mix cure.make" uses the Makefile to compile all your C/C++ code.

## More information regarding Ports

- [Erlang documentation](http://www.erlang.org/doc/tutorial/c_port.html)
- [Elixir](http://elixir-lang.org/docs/stable/elixir/Port.html)

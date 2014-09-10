defmodule Cure.Server do
  use GenServer

  @moduledoc """
  The server is responsible for the communication between Elixir and C.
  The communication is based on Erlang Ports.
  """
  # Replies to the last PID that send data to this process!
  
  @port_options [:binary, :use_stdio, packet: 2]
  
  defmodule State do
    defstruct port: nil, queue: [] # list of {pid, funs} (funs can be nil)
  end

  @doc """
  Starts a Cure.Server process and opens a Port that can communicate with a
  C-program.
  """
  @spec start(String.t) :: GenServer.on_start
  def start(program_name) when program_name |> is_binary do
    GenServer.start(__MODULE__, [program_name])
  end

  @doc """
  Starts a Cure.Server process, links it to the calling process and opens a 
  Port that can communicate with a C-program.
  """
  @spec start(String.t) :: GenServer.on_start
  def start_link(program_name) when program_name |> is_binary do
    GenServer.start_link(__MODULE__, [program_name])
  end

  @doc false
  def init([program_name]) do
    Process.flag(:trap_exit, true)
    port = Port.open({:spawn, program_name}, @port_options)
    #port = Port.open({:spawn, abs_path(program_name)}, @port_options)
    {:ok, %State{port: port}}
  end

  @doc """
  Sends binary data to the C-program that the server is connected with. A 
  callback-function (arity 1) can be added to handle the incoming response of
  the C-program. If no callback is provided, the result is sent back to the
  process that called this function. If the third argument is :sync, this
  function blocks and returns the result.
  """
  @spec send_data(pid, binary) :: :ok
  def send_data(server, msg) when server |> is_pid and msg |> is_binary do
    server |> send_data(msg, nil)
  end
  @spec send_data(pid, binary, ((binary) -> any) | nil | :sync) :: :ok | binary
  def send_data(server, msg, callback) 
      when server |> is_pid
      and msg |> is_binary
      and (callback |> is_function(1) or callback |> is_nil) do
    server |> GenServer.cast({:data, self, msg, callback})
  end
  def send_data(server, msg, :sync) 
      when server |> is_pid 
      and msg |> is_binary do
    server |> GenServer.call({:data, msg})
  end

  @doc """
  Stops the server process.
  """
  @spec stop(pid) :: :ok
  def stop(server) when server |> is_pid do
    GenServer.cast(server, :stop)
  end

  @doc false
  def handle_call({:data, msg}, _from, %State{port: port} = state) do
    port |> Port.command(msg)
    result = receive do
    {^port, {:data, value}} -> value
    after 1000 -> :timeout
    end
    {:reply, result, state}
  end

  @doc false
  def handle_cast({:data, from, msg, nil}, %State{port: port} = state) do
    state = %State{state | queue: [{from, nil} | state.queue]}
    port |> Port.command(msg)
    {:noreply, state}
  end
  def handle_cast({:data, from, msg, callback}, %State{port: port} = state) do
    state = %State{state | queue: [{from, callback} | state.queue]}
    port |> Port.command(msg)
    {:noreply, state}
  end
  def handle_cast(:stop, %State{port: port} = state) do
    port |> Port.close
    {:stop, :normal, state}
  end

  @doc false
  def handle_info({_port, {:data, msg}}, %State{queue: queue} = state) do
    {remaining, [oldest]} = Enum.split(queue, -1)
    state = %State{state | queue: remaining}
    
    case oldest do
      {_, callback} when callback |> is_function(1) ->
        spawn(fn -> apply(callback, [msg]) end)
      {oldest_pid, nil} ->
        oldest_pid |> send({:cure_data, msg})
    end
    
    {:noreply, state}
  end
  def handle_info({:EXIT, _port, reason}, state) do
    IO.puts "Port closed, reason: #{reason}."
    {:stop, :normal, state}
  end
end

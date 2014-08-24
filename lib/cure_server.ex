defmodule Cure.Server do
  use GenServer

  # Replies to the last PID that send data to this process!
  
  @c_dir "./c_src/"
  @port_options [:binary, :use_stdio, packet: 2]
  
  defmodule State do
    defstruct port: nil, queue: [] # list of {pid, funs} (funs can be nil)
  end

  def start(program_name) when program_name |> is_binary do
    GenServer.start(__MODULE__, [program_name])
  end

  def start_link(program_name) when program_name |> is_binary do
    GenServer.start_link(__MODULE__, [program_name])
  end

  def init([program_name]) do
    Process.flag(:trap_exit, true)
    port = Port.open({:spawn, abs_path(program_name)}, @port_options)
    {:ok, %State{port: port}}
  end

  def send_data(server, msg) when server |> is_pid and msg |> is_binary do
    server |> send_data(msg, nil)
  end
  def send_data(server, msg, callback) 
      when server |> is_pid
      and msg |> is_binary
      and (callback |> is_function(1) or nil? callback) do
    server |> GenServer.cast({:data, self, msg, callback})
  end

  def stop(server) when server |> is_pid do
    GenServer.cast(server, :stop)
  end

  def handle_cast({:data, from, msg, nil}, state) do
    state = %State{state | queue: [{from, nil} | state.queue]}
    state.port |> Port.command(msg)
    {:noreply, state}
  end
  def handle_cast({:data, from, msg, callback}, state) do
    state = %State{state | queue: [{from, callback} | state.queue]}
    state.port |> Port.command(msg)
    {:noreply, state}
  end

  def handle_cast(:stop, state) do
    state.port |> Port.close
    {:stop, :normal, state}
  end

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

  # Helper functions:
  defp abs_path(program_name) do
    Path.expand @c_dir <> program_name
  end
end

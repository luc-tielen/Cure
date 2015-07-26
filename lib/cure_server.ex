defmodule Cure.Server do
  use GenEvent
  alias Cure.Queue, as: Queue
  require Logger

  @moduledoc """
  The server is responsible for the communication between Elixir and C/C++.
  The communication is based on Erlang Ports.
  """

  @port_options [:binary, :use_stdio, packet: 2]

  defmodule State do
    defstruct port: nil, mgr: nil, queue: Queue.new, subs: []
  end

  ## API

  @doc """
  Starts a Cure.Server process and opens a Port that can communicate with a
  C/C++ program.
  """
  @spec start(String.t) :: GenEvent.on_start
  def start(program_name) when program_name |> is_binary do
    {ok, mgr} = GenEvent.start
    mgr |> GenEvent.add_handler(__MODULE__, [program_name, mgr])
    {ok, mgr}
  end
  
  @doc """
  Starts a Cure.Server process, links it to the calling process and opens a 
  Port that can communicate with a C/C++ program.
  """
  @spec start_link(String.t) :: GenEvent.on_start
  def start_link(program_name) when program_name |> is_binary do
    {ok, mgr} = GenEvent.start_link
    mgr |> GenEvent.add_handler(__MODULE__, [program_name, mgr])
    {ok, mgr}
  end

  @doc """
  Stops the server process.
  """
  @spec stop(pid) :: :ok
  def stop(mgr) when mgr |> is_pid  do
    mgr |> GenEvent.stop
  end

  @doc """
  Subscribes the calling process to receive data events from the server process.
  """
  @spec subscribe(pid) :: :ok  
  def subscribe(mgr) when mgr |> is_pid do
    mgr |> GenEvent.sync_notify {:subscribe, self}
  end

  @doc """
  Adds an extra callback function to the server that is triggered on all
  incoming data.
  """
  @spec subscribe(pid, ((binary) -> any)) :: :ok
  def subscribe(mgr, fun) when mgr |> is_pid and fun |> is_function(1) do
    mgr |> GenEvent.sync_notify {:subscribe_callback, fun}
  end

  @doc """
  Unsubscribes the calling process from receiving further data events coming 
  from the server process.
  """
  @spec unsubscribe(pid) :: :ok
  def unsubscribe(mgr) do
    mgr |> GenEvent.sync_notify {:unsubscribe, self}
  end

  @doc """
  Removes a callback that was applied to all incoming data events.
  NOTE: this has to be the exact same callback function that was registered
  earlier with subscribe in order for this function to work properly.
  """
  @spec unsubscribe(pid, ((binary) -> any)) :: :ok
  def unsubscribe(mgr, fun) do
    mgr |> GenEvent.sync_notify {:unsubscribe_callback, fun}
  end

  @doc """
  Sends binary data to the C/C++ program that the server is connected with. A 
  callback-function (arity 1) can be added to handle the incoming response of
  the program. If no callback is added, the response will be sent to the 
  calling process of this function. 
  
  The third argument indicates how the response should be handled. Possible 
  modes for handling the response are the following:
  
  :once -> callback function is only applied once.
  :permanent -> callback function is applied to all following events
  :sync -> the server waits with further events until response is processed
  (no timeout specified = :infinity).
  """
  @spec send_data(pid, binary, :once | :permanent | :sync, 
                  ((binary) -> any) | timeout) :: :ok
  def send_data(mgr, data, :once, callback) 
      when mgr |> is_pid 
      and data |> is_binary 
      and callback |> is_function(1) do
    mgr |> GenEvent.sync_notify {:data, data, :once, {:function, callback}}
  end
  def send_data(mgr, data, :permanent, callback) 
      when mgr |> is_pid 
      and data |> is_binary
      and callback |> is_function(1) do
    mgr |> subscribe callback
    mgr |> send_data(data, :noreply)
  end
  def send_data(mgr, data, :sync, callback) 
      when mgr |> is_pid 
      and data |> is_binary 
      and callback |> is_function(1) do
    mgr |> send_data(data, :sync, callback, :infinity)
  end
  def send_data(mgr, data, :sync, timeout) 
      when mgr |> is_pid
      and data |> is_binary 
      and (timeout == :infinity or (timeout |> is_number and timeout >= 0)) do
    mgr |> GenEvent.sync_notify {:data, data, :sync, timeout, {:pid, self}}
    receive do 
      {:cure_data, msg} -> msg
    end
  end

  @doc """
  Sends binary data to the C/C++ program that the server is connected with.
  The server waits with processing further events until the response for this
  function is handled.
  """
  @spec send_data(pid, binary, :sync, ((binary) -> any), timeout) :: :ok
  def send_data(mgr, data, :sync, callback, timeout) 
      when mgr |> is_pid
      and data |> is_binary
      and callback |> is_function(1)
      and (timeout == :infinity or (timeout |> is_number and timeout > 0)) do
    mgr |> GenEvent.sync_notify {:data, data, :sync, timeout, 
                                  {:function, callback}}
  end
  
  @doc """
  Sends binary data to the C/C++ program that the server is connected with. 
  The result is sent back to the process that called this function. The third
  argument indicates how the response should be handled. Possible modes for 
  handling the response are the following:
  
  :once -> Only the first event will be sent back to the calling process.
  :noreply -> No event will be sent back to the calling process.
  :permanent -> All following events will be sent back to the calling process.
  :sync -> the server waits with processing further events until the response is
  sent back to the calling process (timeout = :infinity unless specified).
  """
  @spec send_data(pid, binary, 
                  :once | :noreply | :permanent, :sync) :: :ok | {:error, term}
  def send_data(mgr, data, :once) when mgr |> is_pid
                                  and data |> is_binary do
    mgr |> GenEvent.sync_notify {:data, data, :once, {:pid, self}}
  end
  def send_data(mgr, data, :noreply) when mgr |> is_pid
                                      and data |> is_binary do
    mgr |> GenEvent.sync_notify {:data, data, :noreply}
  end
  def send_data(mgr, data, :permanent) when mgr |> is_pid 
                                      and data |> is_binary do
    mgr |> subscribe
    mgr |> send_data(data, :noreply)
  end
  def send_data(mgr, data, :sync) when mgr |> is_pid 
                                  and data |> is_binary do
    mgr |> send_data(data, :sync, :infinity)
  end


  ## Callbacks

  @doc false
  def init([program_name, mgr]) do
    Process.flag(:trap_exit, true)
    port = Port.open({:spawn, program_name}, @port_options)
    {:ok, %State{port: port, mgr: mgr}}
  end

  @doc false
  def terminate(:stop, %State{port: port}) do
    port |> Port.close
    :ok
  end

  @doc false
  def handle_event({:subscribe, pid}, state = %State{subs: subs}) do
    new_subs = subs |> add_sub {:pid, pid} 
    {:ok, %State{state | subs: new_subs}}
  end
  def handle_event({:unsubscribe, pid}, state = %State{subs: subs}) do
    {:ok, %State{state | subs: List.delete(subs, {:pid, pid})}}
  end
  def handle_event({:subscribe_callback, fun}, state = %State{subs: subs}) do
    new_subs = subs |> add_sub {:function, fun}
    {:ok, %State{state | subs: new_subs}}
  end
  def handle_event({:unsubscribe_callback, fun}, state = %State{subs: subs}) do
    {:ok, %State{state | subs: List.delete(subs, {:function, fun})}}
  end
  def handle_event({:data, data, :once, callback}, 
                    state = %State{port: port, queue: queue}) do
    new_state = %State{state | queue: Queue.push(queue, callback)}
    port |> Port.command(data)
    {:ok, new_state}
  end
  def handle_event({:data, data, :noreply},
                    state = %State{port: port, queue: queue}) do
    new_state = %State{state | queue: Queue.push(queue, :noreply)}
    port |> Port.command(data)
    {:ok, new_state}
  end
  def handle_event({:data, data, :sync, timeout, cb}, 
                    state = %State{port: port}) do
    port |> Port.command(data)
    
    result = receive do
      {^port, {:data, value}} -> value
      after timeout -> :timeout
    end

    cb |> handle_msg(result)

    {:ok, state}
  end


  ## Port related callbacks

   @doc false
   def handle_info({_port, {:data, msg}}, state = %State{queue: {[], []}, 
                                                        subs: subs}) do
    spawn fn ->
      subs |> Enum.map fn(sub) ->
        sub |> handle_msg(msg)
      end
    end

    {:ok, state}
  end 
  def handle_info({_port, {:data, msg}}, state = %State{queue: queue,
                                                        subs: subs}) do
    {remaining, value: oldest} = Queue.pop(queue)
    state = %State{state | queue: remaining}
    oldest |> handle_msg(msg)

    spawn fn ->
      subs |> Enum.map fn(sub) ->
        sub |> handle_msg(msg)
      end
    end
    
    {:ok, state}
  end
  def handle_info({:EXIT, _port, reason}, state = %State{mgr: mgr}) do
    Logger.debug "Cure Server: Port closed, reason: #{reason}."
    mgr |> stop
    {:ok, state}
  end


  # Helper functions:

  defp handle_msg({:pid, pid}, msg) do
    pid |> send {:cure_data, msg}
  end
  defp handle_msg({:function, callback}, msg) do
    spawn fn -> 
      apply(callback, [msg])
    end
  end
  defp handle_msg(:noreply, _msg), do: :ok

  defp add_sub(subs, new_sub) do
    if new_sub in subs, do: subs, else: [new_sub | subs]
  end
end

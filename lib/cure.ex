defmodule Cure do
  use Application

  @moduledoc """
  The main Cure module. Provides a few functions to easily start a connection
  with a C/C++ program, to send messages to the program and to handle the
  incoming responses.
  """

  @doc """
  Starts the Cure application, returns the Cure.Supervisor-PID.
  """
  @spec start(any, any) :: {:ok, pid} | {:error, term}
  def start(_type, _args) do
    Cure.Supervisor.start_link
  end

  @doc """
  Starts a Cure.Server process that can communicate with a C-program.
  """
  @spec load(String.t) :: {:ok, pid}
  def load(c_program_name) when c_program_name |> is_binary do
    Cure.Supervisor.start_child(c_program_name)
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

  (Same effect as calling Cure.Server.send_data directly.)
  """
  @spec send_data(pid, binary, :once | :permanent | :sync, 
                  ((binary) -> any) | timeout) :: :ok
  def send_data(server, data, :once, callback) do
    server |> Cure.Server.send_data(data, :once, callback)
  end
  def send_data(server, data, :permanent, callback) do
    server |> Cure.Server.send_data(data, :permanent, callback)
  end
  def send_data(server, data, :sync, callback) when is_function(1, callback) do
    server |> Cure.Server.send_data(data, :sync, callback)
  end
  def send_data(server, data, :sync, timeout) do
    server |> Cure.Server.send_data(data, :sync, timeout)
  end

  @doc """
  Sends binary data to the C/C++ program that the server is connected with.
  The server waits with processing further events until the response for this
  function is handled.
  
  (Same effect as calling Cure.Server.send_data directly.)
  """
  @spec send_data(pid, binary, :sync, ((binary) -> any), timeout) :: :ok
  def send_data(server, data, :sync, callback, timeout) do
    server |> Cure.Server.send_data(data, :sync, callback, timeout)
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
  
  (Same effect as calling Cure.Server.send_data directly.)
  """
  @spec send_data(pid, binary, 
                  :once | :noreply | :permanent, :sync) :: :ok | {:error, term}
  def send_data(server, data, :once) do
    server |> Cure.Server.send_data(data, :once)
  end
  def send_data(server, data, :noreply) do
    server |> Cure.Server.send_data(data, :noreply)
  end
  def send_data(server, data, :permanent) do
    server |> Cure.Server.send_data(data, :permanent)
  end
  def send_data(server, data, :sync) do
    server |> Cure.Server.send_data(data, :sync)
  end
 
  @doc """
  Returns a stream that consumes data events coming from the C/C++ program.
  """
  @spec stream(pid) :: GenEvent.Stream.t
  def stream(server), do: server |> Cure.Server.stream

  @doc """
  Subscribes the calling process to receive data events from the server process.
  """
  @spec subscribe(pid) :: :ok
  def subscribe(server), do: server |> Cure.Server.subscribe

  @doc """
  Adds an extra callback function to the server that is triggered on all
  incoming data.
  """
  @spec subscribe(pid, ((binary) -> any)) :: :ok
  def subscribe(server, fun), do: server |> Cure.Server.subscribe(fun)

  @doc """
  Unsubscribes the calling process from receiving further data events coming 
  from the server process.
  """
  @spec unsubscribe(pid) :: :ok
  def unsubscribe(server), do: server |> Cure.Server.unsubscribe

  @doc """
  Removes a callback that was applied to all incoming data events.
  NOTE: this has to be the exact same callback function that was registered
  earlier with subscribe in order for this function to work properly.
  """
  @spec unsubscribe(pid, ((binary) -> any)) :: :ok
  def unsubscribe(server, fun), do: server |> Cure.Server.unsubscribe(fun)

  @doc """
  Stops a server process.
  """
  @spec stop(pid) :: :ok
  def stop(server) when server |> is_pid do
    # If the server is supervised it has to be removed from there, otherwise
    # supervisor will restart it and the C-program will stay activated.
    server |> Cure.Supervisor.terminate_child
    server |> Cure.Server.stop
  end
end

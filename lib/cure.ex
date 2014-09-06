defmodule Cure do
  use Application

  @moduledoc """
  The main Cure module. Provides a few functions to easily start a connection
  with a C-program, to send messages to the C-program and to handle the
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
  Sends binary data to the C-program that the server is connected with. A 
  callback function (arity 1) can be added to handle the incoming response of
  the C-program. If no callback is added, the result is sent back to the
  process that called this function. If the third argument is :sync, this
  function blocks and returns the output from the C-program.

  (Same effect as calling Cure.Server.send_data directly.)
  """
  @spec send_data(pid, binary) :: :ok
  def send_data(server, msg) 
      when server |> is_pid 
      and msg |> is_binary do
    server |> send_data(msg, nil)
  end
  @spec send_data(pid, binary, ((binary) -> any) | nil | :sync) :: :ok | binary
  def send_data(server, msg, callback) 
      when server |> is_pid 
      and msg |> is_binary 
      and (callback |> is_function(1) or callback |> is_nil) do
    server |> Cure.Server.send_data(msg, callback)
  end 
  def send_data(server, msg, :sync) 
      when server |> is_pid 
      and msg |> is_binary do
    server |> Cure.Server.send_data(msg, :sync)
  end

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

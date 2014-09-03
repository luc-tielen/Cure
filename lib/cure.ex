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
  def start(_type, _args) do
    Cure.Supervisor.start_link
  end

  @doc """
  Starts a Cure.Server process that can communicate with a C-program.
  """
  def load(c_program_name) when c_program_name |> is_binary do
    Cure.Supervisor.start_child(c_program_name)
  end
  
  @doc """
  Sends binary data to the C-program that the server is connected with. Returns
  the output from the C-program as binary data.
  """
  def send_data(server, msg, :sync) do
    server |> Cure.Server.send_data(msg, :sync)
  end

  @doc """
  Sends binary data to the C-program that the server is connected with. A 
  callback function (arity 1) can be added to handle the incoming response of
  the C-program. If no callback is added, the result is sent back to the
  process that called this function.

  (Same as calling Cure.Server.send_data directly.)
  """
  def send_data(server, msg, callback \\ nil) 
      when server |> is_pid 
      and msg |> is_binary 
      and (callback |> is_function(1) or nil? callback) do
    server |> Cure.Server.send_data(msg, callback)
  end

  @doc """
  Stops a server process.
  """
  def stop(server) when server |> is_pid do
    # If the server is supervised it has to be removed from there, otherwise
    # supervisor will restart it and the C-program will stay activated.
    server |> Cure.Supervisor.terminate_child
    server |> Cure.Server.stop
  end
end

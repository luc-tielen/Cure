defmodule Cure.Port do

  @moduledoc """
  Module that can communicate with C using a Port directly (no
  GenServer/Supervisor is used here, currently only supports synchronous
  communication).
  """

  @port_options [:binary, :use_stdio, packet: 2]

  @doc """
  Opens a Port that can communicate with a C-program.
  """
  def load(program_location) when program_location |> is_binary do
    # TODO check if this always loads the right program.
    Port.open({:spawn, program_location}, @port_options)
  end

  @doc """
  Sends data to a Port. This function blocks until a reply is 
  received or until the function times out (default is 1 second).
  """
  def send_data(port, data, timeout \\ 1000) 
      when port |> is_port 
      and data |> is_binary 
      and (timeout |> is_number or timeout == :infinity) do
    port |> Port.command(data)
    receive do
      {^port, {:data, msg}} -> msg
    after timeout -> :timeout
    end
  end

  @doc """
  Closes a Port.
  """
  def close(port) when port |> is_port do
    port |> Port.close
  end
end

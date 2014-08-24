defmodule Cure do
  use Application

  def start(_type, _args) do
    Cure.Supervisor.start_link
  end

  def load(c_program_name) when c_program_name |> is_binary do
    Cure.Supervisor.start_child(c_program_name)
  end

  def send_data(server, msg, callback \\ nil) 
      when server |> is_pid 
      and msg |> is_binary 
      and (callback |> is_function(1) or nil? callback) do
    server |> Cure.Server.send_data(msg, callback)
  end
end

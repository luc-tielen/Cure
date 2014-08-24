defmodule Cure.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def start_child(program_name) when program_name |> is_binary do
    Supervisor.start_child(__MODULE__, [program_name])
  end

  def init(:ok) do
    children = [worker(Cure.Server, [])]
    supervise(children, strategy: :simple_one_for_one)
  end
end

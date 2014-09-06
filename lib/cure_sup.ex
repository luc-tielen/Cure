defmodule Cure.Supervisor do
  use Supervisor

  @moduledoc """
  The supervisor is responsible for monitoring Cure.Server processes.
  Can be optionally left out by starting a Cure.Server process directly.
  """

  @doc """
  Starts a Cure.Supervisor process (registered as Cure.Supervisor).
  """
  @spec start_link() :: Supervisor.on_start
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @doc """
  Starts a Cure.Server process that is monitored by the Cure.Supervisor
  process.
  """
  @spec start_child(String.t) :: Supervisor.on_start_child
  def start_child(program_name) when program_name |> is_binary do
    Supervisor.start_child(__MODULE__, [program_name])
  end

  @doc """
  Terminates a Cure.Server process.
  """
  @spec terminate_child(pid) :: :ok | {:error, term}
  def terminate_child(server_pid) when server_pid |> is_pid do
    Supervisor.terminate_child(__MODULE__, server_pid)
  end

  @doc """
  Terminates all supervised Cure.Server processes.
  """
  @spec terminate_children() :: [:ok | {:error, term}]
  def terminate_children do
    children = Supervisor.which_children(__MODULE__)
    children |> Enum.map(fn({:undefined, pid, :worker, [Cure.Server]}) -> 
      pid |> terminate_child
    end)
  end

  @doc false
  def init(:ok) do
    children = [worker(Cure.Server, [])]
    supervise(children, strategy: :simple_one_for_one)
  end
end

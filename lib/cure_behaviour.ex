defmodule Cure.Behaviour do

  @moduledoc """
  Module containing macros to facilitate making your own Cure.Server-like
  process.
  """

  # TODO add tests later!

  defmacro __using__(_opts) do
    quote location: :keep do
      use GenServer
      import Cure.Behaviour
      
      defmodule State do 
        # find a way to remove this later, complains about using %State{}
        # otherwise
        defstruct port: nil, queue: []
      end
      
      @doc """
      Starts a Cure.Server process and opens a Port that can communicate with a
      C-program.
      """
      def start do
        GenServer.start(__MODULE__, [])
      end
      def start(params) when is_list(params) do
        GenServer.start(__MODULE__, [params])
      end

      @doc """
      Starts a Cure.Server process, links it to the calling process and opens a 
      Port that can communicate with a C-program.
      """
      def start_link do
        GenServer.start_link(__MODULE__, [])
      end
      def start_link(params) when is_list(params) do
        GenServer.start_link(__MODULE__, [params])
      end

      @doc false
      def init([params]) do
        Process.flag(:trap_exit, true)
        port = init_port(program_location)
        {:ok, state} = on_initialize(port, params)
        {:ok, %State{state | port: port}}
      end

      @doc """
      Sends binary data to the C-program that the server is connected with. A 
      callback function (arity 1) can be added to handle the incoming response 
      of the C-program. If no callback is added, the result is sent back to the
      process that called this function.
      """
      def send_data(server, msg) when server |> is_pid and msg |> is_binary do
        server |> send_data(msg, nil)
      end
      def send_data(server, msg, callback) 
          when server |> is_pid
          and msg |> is_binary
          and (callback |> is_function(1) or nil? callback) do
        server |> GenServer.cast({:data, self, msg, callback})
      end

      @doc """
      Stops the server process.
      """
      def stop(server) when server |> is_pid do
        GenServer.cast(server, :stop)
      end
      
      @doc false
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

      defp send_to_port(port, data) when is_port(port) and is_binary(data) do
        port |> Port.command(data)
      end

      defp program_location, do: nil 
      defp port_options, do: [:binary, :use_stdio, packet: 2]
      defp init_port(program), do: Port.open({:spawn, program}, port_options)

      defp on_initialize(port, []) when port |> is_port, do: %State{}
      defp on_initialize(port, kwl) when port |> is_port and kwl |> is_list do
        # TODO put keyword list into struct? or leave this as default
        # behaviour?
        %State{}
      end

      defoverridable [program_location: 0, on_initialize: 2]
    end
  end

  @doc """
  Creates a struct that also contains a few required fields for proper use of 
  the behaviour.
  """
  defmacro defcurestruct(fields) do
    quote bind_quoted: [fields: fields] do
      defstruct fields ++ [port: nil, queue: []]
    end
  end
  defmacro defcurestruct do
    quote do
      defstruct port: nil, queue: []
    end
  end
end

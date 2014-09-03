defmodule Cure.ServerTest do
  use ExUnit.Case, async: true

  @program_name "./test/test_echo_program"

  # First compile a little C-program that echo's data back.
  setup do
    unless File.exists?(@program_name) do
      IO.puts "Compiling test_program."
      System.cmd "make", ["-C", "./test/"]
    end
    :ok
  end

  test "Starting and stopping of server." do
    {:ok, server} = Cure.Server.start @program_name
    assert Process.alive?(server) == true
    server |> Cure.Server.stop
    :timer.sleep 5
    assert Process.alive?(server) == false
  end

  test "Sending and recieving messages from Elixir to C" do
    str = "Test data"
    pid = self

    {:ok, server} = Cure.Server.start @program_name
    server |> Cure.Server.send_data str
    assert_receive {:cure_data, ^str}

    server |> Cure.Server.send_data(str, fn(data) ->
      # Putting an assert here doesn't really work so we send the msg back..
      pid |> send {:test_data, data}
    end)
    assert_receive {:test_data, ^str}

    assert Cure.Server.send_data(server, str, :sync) == str
  end
end

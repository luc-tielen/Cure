defmodule Cure.ServerTest do
  use ExUnit.Case, async: true

  @program_name "./test/test_echo_program"

  # First compile a little C-program that echo's data back.
  setup_all do
    unless File.exists?(@program_name) do
      IO.puts "Compiling test_program."
      System.cmd "make", ["-C", "./test/"]
    end
    :ok
  end

  test "Starting and stopping of server (no supervision)" do
    {:ok, server} = Cure.Server.start @program_name
    assert Process.alive?(server) == true
    server |> Cure.Server.stop
    :timer.sleep 5
    assert Process.alive?(server) == false
  end

  # The send_data functions are already covered in cure_test.exs
end

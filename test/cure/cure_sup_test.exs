defmodule Cure.SupervisorTest do
  use ExUnit.Case, async: true

  @program_name "./test/test_echo_program"
  
  setup do
    unless File.exists?(@program_name) do
      IO.puts "Compiling test_program."
      System.cmd "make", ["-C", "./test/"]
    end
    :ok
  end

  test "Starting/stopping supervisor" do
    Application.stop :cure
    assert Process.whereis(Cure.Supervisor) == nil

    Application.start :cure
    supervisor = Process.whereis(Cure.Supervisor)
    refute Process.whereis(Cure.Supervisor) == nil
    assert Process.alive?(supervisor) == true
  end

  test "Adding/removing children" do
    supervisor = Process.whereis(Cure.Supervisor)
    refute supervisor == nil
    {:ok, server1} = Cure.Supervisor.start_child @program_name
    {:ok, _server2} = Cure.Supervisor.start_child @program_name
    
    children = Supervisor.which_children(supervisor)
    assert length(children) == 2

    Cure.Supervisor.terminate_child server1
    children = Supervisor.which_children(supervisor)
    assert length(children) == 1
  
    {:ok, _server3} = Cure.Supervisor.start_child @program_name
    Cure.Supervisor.terminate_children
    children = Supervisor.which_children(supervisor)
    assert length(children) == 0
  end
end

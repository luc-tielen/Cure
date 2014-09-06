defmodule CurePortTest do
  use ExUnit.Case

  @program_name "./test/test_echo_program"
 
  # First compile a little C-program that echo's data back.
  setup do
    unless File.exists?(@program_name) do
      IO.puts "Compiling test_program."
      System.cmd "make", ["-C", "./test/"]
    end
    :ok
  end

  test "normal workflow using port" do
    # caller = self
    # msg = "testing"
    # str = "more text"

    port = Cure.Port.load(@program_name)
    assert is_port(port)

    assert <<1,2,3,4>> == port |> Cure.Port.send_data(<<1,2,3,4>>)
    assert Cure.Port.close(port) == :ok
  end
end

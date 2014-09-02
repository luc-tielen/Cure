defmodule CureTest do
  use ExUnit.Case

  @program_name "./test/test_echo_program"

  setup do
    unless File.exists?(@program_name) do
      IO.puts "Compiling test_program."
      System.cmd "make", ["-C", "./test/"]
    end
    :ok
  end
  
  test "Test normal workflow" do
    pid = self
    data1 = "testing 1,2,3"
    data2 = <<0, 1, 2, 3, 4, 5>>

    {:ok, server} = Cure.load @program_name
    server |> Cure.send_data data1
    assert_receive {:cure_data, ^data1}

    server |> Cure.send_data data2, fn(data) ->
      # Weird results if you do assert here so we send msg back first
      pid |> send {:data_from_callback, data}
    end
    assert_receive {:data_from_callback, ^data2}
  end
end

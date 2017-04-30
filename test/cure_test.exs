defmodule CureTest do
  use ExUnit.Case

  @program_name "./test/test_echo_program"

  setup_all do
    unless File.exists?(@program_name) do
      IO.puts "Compiling test_program."
      System.cmd "make", ["-C", "./test/"]
    end
    :ok
  end

  test "Test a message that overflows C 'signed char' size" do
    data = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

    {:ok, server} = Cure.load @program_name

    assert data == server |> Cure.send_data(data, :sync, 5000)

    :ok = server |> Cure.stop
  end

  test "Test normal workflow using :sync messages" do
    pid = self
    data1 = "testing 1,2,3"
    data2 = <<0, 1, 2, 3, 4, 5>>

    {:ok, server} = Cure.load @program_name
    
    # 3 args version
    assert data1 == server |> Cure.send_data(data1, :sync)
    assert data2 == server |> Cure.send_data(data2, :sync)

    # 4 args version
    assert data1 == server |> Cure.send_data(data1, :sync, 5000)
    assert data2 == server |> Cure.send_data(data2, :sync, :infinity)

    server |> Cure.send_data(data1, :sync, fn(data) ->
      # Weird results if you do assert here so we send msg back first
      pid |> send({:data_from_callback, data})
    end)
    assert_receive {:data_from_callback, ^data1}

    # 5 args version
    server |> Cure.send_data(data2, :sync, fn(data) ->
      pid |> send({:data_from_callback, data})
    end, 5000)
    assert_receive {:data_from_callback, ^data2}

    :ok = server |> Cure.stop
  end

  test "Test normal workflow using :permanent and :noreply messages" do
    pid = self
    data = "12345"

    # 3 args
    {:ok, server} = Cure.load @program_name

    server |> Cure.send_data(data, :noreply)
    refute_receive {:cure_data, ^data}

    server |> Cure.send_data(data, :permanent)
    assert_receive {:cure_data, ^data}

    server |> Cure.send_data(data, :noreply)
    assert_receive {:cure_data, ^data}

    :ok = server |> Cure.stop

    # 4 args
    {:ok, server} = Cure.load @program_name

    server |> Cure.send_data(data, :noreply)
    refute_receive {:test_data, ^data}

    server |> Cure.send_data(data, :permanent, fn(msg) ->
      pid |> send({:test_data, msg})
    end)
    assert_receive {:test_data, ^data}

    server |> Cure.send_data(data, :noreply)
    assert_receive {:test_data, ^data}

    :ok = server |> Cure.stop
  end

  test "Workflow using :once messages" do
    pid = self
    data = "abc"
    {:ok, server} = Cure.load @program_name

    # 3 args
    server |> Cure.send_data(data, :once)
    assert_receive {:cure_data, ^data}
    
    server |> Cure.send_data(data, :noreply)
    refute_receive {:cure_data, ^data}

    # 4 args
    server |> Cure.send_data(data, :once, fn(msg) ->
      pid |> send({:test_data, msg})
    end)
    assert_receive {:test_data, ^data}

    server |> Cure.send_data(data, :noreply)
    refute_receive {:test_data, ^data}

    :ok = server |> Cure.stop
  end

  test "Subscribing and unsubscribing to data events" do
    pid = self 
    data = "xyz"
    cb = fn(msg) ->
      pid |> send({:subscriber_data, msg})
    end

    {:ok, server} = Cure.load @program_name
    
    server |> Cure.send_data(data, :noreply)
    refute_receive {:cure_data, ^data}

    # Subscribe with process
    server |> Cure.subscribe
    server |> Cure.send_data(data, :noreply)
    assert_receive {:cure_data, ^data}

    server |> Cure.unsubscribe
    server |> Cure.send_data(data, :noreply)
    refute_receive {:cure_data, ^data}

    # Subscribe with callback
    server |> Cure.subscribe(cb)
    server |> Cure.send_data(data, :noreply)
    assert_receive {:subscriber_data, ^data}

    server |> Cure.unsubscribe(cb)
    server |> Cure.send_data(data, :noreply)
    refute_receive {:subscriber_data, ^data}
  
    :ok = server |> Cure.stop
  end
end

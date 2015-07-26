defmodule QueueTest do
  use ExUnit.Case, async: true
  alias Cure.Queue, as: Q

  test "making new queues" do
    list = [1, 2, 3]
    err = FunctionClauseError

    assert Q.new == {[], []}
    assert Q.from_list(list) == {list, []}
    assert_raise err, fn -> Q.from_list %{} end
    assert_raise err, fn -> Q.from_list {} end
    # etc..
  end

  test "push and pop to/from queue" do
    data1 = :test
    data2 = 1
    data3 = %{testing: 123}

    a = Q.new
    b =
      a
      |> Q.push(data1)
      |> Q.push(data2)
      |> Q.push(data3)
    {c, value: c_value} = Q.pop(b)
    {d, value: d_value} = Q.pop(c)
    {e, value: e_value} = Q.pop(d)
    {f, value: f_value} = Q.pop(e)
    
    expected_inputs_b = [data3, data2, data1]
    expected_outputs_b = []
    expected_inputs_c = []
    expected_outputs_c = [data2, data3]
    expected_value_c = data1
    expected_inputs_d = []
    expected_outputs_d = [data3]
    expected_value_d = data2
    expected_inputs_e = []
    expected_outputs_e = []
    expected_value_e = data3
    expected_inputs_f = []
    expected_outputs_f = []
    expected_value_f = nil

    assert b == {expected_inputs_b, expected_outputs_b}
    assert c == {expected_inputs_c, expected_outputs_c}
    assert d == {expected_inputs_d, expected_outputs_d}
    assert e == {expected_inputs_e, expected_outputs_e}
    assert f == {expected_inputs_f, expected_outputs_f}
    assert c_value == expected_value_c
    assert d_value == expected_value_d
    assert e_value == expected_value_e
    assert f_value == expected_value_f
    assert Q.empty?(e)
    assert Q.empty?(f)
  end

  test "dropping elements out of queue" do
    a = 
      Q.from_list([1, 2, 3]) 
      |> Q.drop
      |> Q.push(:test)
    b = Q.drop(a)
    c = Q.drop(b)
    d = Q.drop(c)
    e = Q.drop(d)

    assert a == {[:test], [2, 1]}
    assert b == {[:test], [1]}
    assert c == {[:test], []}
    assert d == {[], []}
    assert e == {[], []}
  end

  test "reversing" do
    list1 = [1, 2, 3, 4, 5]
    list2 = [1, 2, 3, 4]
    reverse_list1 = Enum.reverse(list1)

    a = Q.from_list(list1)
    {b, value: _} = Q.pop(a)  # contains [1, 2, 3, 4], []
    c = Q.push(b, 6)          # contains [1, 2, 3, 4], [6]
    d = Q.push(c, 7)          # contains [1, 2, 3, 4], [6, 7]

    assert Q.reverse(a) == {[], reverse_list1}
    assert Q.reverse(b) == {list2, []}
    assert Q.reverse(c) == {list2, [6]}
    assert Q.reverse(d) == {list2, [6, 7]}
  end

  test "size" do
    a = Q.new
    b = Q.from_list([1, 2, 3])
    c = 
      b 
      |> Q.drop
      |> Q.push(4)
    assert Q.size(a) == 0
    assert Q.size(b) == 3
    assert Q.size(c) == 3
  end

  test "empty?" do
    a = Q.new
    b = 
      Q.from_list([1, 2]) 
      |> Q.drop
      |> Q.push(:test)
    c = Q.drop(b)
    d = Q.push(c, [:test123, %{}])
    e =
      d
      |> Q.drop
      |> Q.drop

    assert Q.empty?(a)
    refute Q.empty?(b)
    refute Q.empty?(c)
    refute Q.empty?(d)
    assert Q.empty?(e)
  end
end

defmodule Cure.Queue do
  @moduledoc """
  Queue module for a FIFO like behavior.
  Based on Erlang's :queue module, but with my own small twist to it for easier use
  in Elixir (usage with |>, etc..)
  """

  @typedoc """
  Queue type. Consists out of a double ended list.
  """
  @type t :: {List.t, List.t}


  # TODO turn tuple into struct + implement Enumerable / Inspect... 
  # => might be worse performance?


  @doc """
  Creates a new queue.
  """
  @spec new() :: Queue.t
  def new, do: {[], []}  # {[input (new -> old)], [output (old -> new)]}

  @doc """
  Creates a queue from a list (newest entry at head of list).
  """
  @spec from_list(List.t) :: Queue.t
  def from_list(list) when is_list(list), do: {list, []}

  @doc """
  Inserts the value into the queue.
  Returns the updated queue.
  """
  @spec push(Queue.t, any) :: Queue.t
  def push(_queue = {input_list, output_list}, value) 
      when is_list(input_list) and is_list(output_list) do
    {[value | input_list], output_list}
  end

  @doc """
  Pops the oldest value from the queue and returns it to the user.
  Value returned is nil if queue = empty.
  """
  @spec pop(Queue.t) :: {Queue.t, value: any}
  def pop(queue = {_input_list = [], _output_list = []}) do
    {queue, value: nil}
  end
  def pop(_queue = {input_list, _output_list = []}) when is_list(input_list) do
    [oldest_value | new_output_list] = Enum.reverse(input_list)
    new_queue = {[], new_output_list}
    {new_queue, value: oldest_value}
  end
  def pop(_queue = {input_list, _output_list = [oldest | rest]}) 
      when is_list(input_list) do
    new_queue = {input_list, rest}
    {new_queue, value: oldest}
  end

  @doc """
  Drops the oldest value from the queue (not returned to the user).
  Does nothing if queue = empty.
  Returns the updated queue.
  """
  @spec drop(Queue.t) :: Queue.t
  def drop(queue = {_input_list = [], _output_list = []}) do
    queue
  end
  def drop(_queue = {input_list, _output_list = []}) 
      when is_list(input_list) do
    [_oldest_value | new_output_list] = Enum.reverse(input_list)
    {[], new_output_list}  # new_queue
  end
  def drop(_queue = {input_list, _output_list = [_oldest | rest]}) 
      when is_list(input_list) do
    {input_list, rest}
  end

  @doc """
  Reverses the queue (oldest item becomes newest, and vice versa).
  """
  @spec reverse(Queue.t) :: Queue.t
  def reverse(_queue = {input_list, output_list}) 
      when is_list(input_list) and is_list(output_list) do
    {Enum.reverse(output_list), Enum.reverse(input_list)}
  end

  @doc """
  Returns amount of elements inside the queue.
  """
  @spec size(Queue.t) :: integer
  def size(_queue = {input_list, output_list}) 
      when is_list(input_list) and is_list(output_list) do
    length(input_list) + length(output_list)
  end

  @doc """
  Checks if current queue is empty.
  """
  @spec empty?(Queue.t) :: Atom
  def empty?(_queue = {[], []}), do: true
  def empty?(_queue), do: false
end

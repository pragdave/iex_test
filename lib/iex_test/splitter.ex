defmodule IexTest.Splitter do

  import Enum, only: [ join: 2, reverse: 1 ]

  @moduledoc """
  Given the contents of an <iex> block, break it into
  groups of inputs and outputs, and return a list of
  tuples where the first element is the lines of input and
  the second the expected lines of output.
  """
  def tee(val, fun), do: (fun.(val); val)

  def split_tests(lines) do
    { preload, code } = split_tests(lines, [], [], [], nil)
    { preload, reverse(code) }
  end

  defp split_tests([], tests, _code, [], preload) do
    { preload, tests }
  end

  defp split_tests([], tests, code, expected, preload) do
    { preload, add_test(code, expected, tests) }
  end

  defp split_tests([<< "$ iex ", rest :: binary >> | t], tests, code, [], _preload) do
    split_tests(t, tests, code, [], String.strip(rest))
  end

  defp split_tests([<< "iex>", rest :: binary >> | t], tests, code, [], preload) do
    split_tests(t, tests, [ rest | code ], [], preload)
  end

  defp split_tests([<< "iex>", rest :: binary >> | t], tests, code, expected, preload) do
    split_tests(t, add_test(code, expected, tests), [ rest ], [], preload)
  end

  defp split_tests([<< "...>", rest :: binary >> | t], tests, code, expected, preload) do
     split_tests(t, tests, [ rest | code ], expected, preload)
  end

  defp split_tests( [ value | t], tests, code, expected, preload) do
    split_tests(t, tests, code, [ value | expected ], preload)
  end


  defp add_test(code, expected, tests) do
    IO.puts "add test #{inspect expected}"
    [ { join(reverse(code), "\n"), reverse(expected) } | tests ]
  end

end

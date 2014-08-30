defmodule IexTest.Splitter do

  import Enum,   only: [ join: 2, map: 2, reverse: 1 ]
  import String, only: [ strip: 1]

  alias IexTest.TestSequence, as: TS
  alias IexTest.Test,         as: T

  @moduledoc """
  Given the contents of an <iex> block, break it into
  groups of inputs and outputs, and return a list of
  tuples where the first element is the lines of input and
  the second the expected lines of output.
  """
  def tee(val, fun), do: (fun.(val); val)

  def split_tests(lines, original_line_number \\ 0) do
    %TS{preload: preload, tests: tests} = split_tests(lines, [], [], [], nil)
    %TS{preload: preload, tests: reverse(tests), line_number: original_line_number}
  end

  defp split_tests([], tests, _code, [], preload) do
    %TS{preload: preload, tests: tests}
  end

  defp split_tests([], tests, code, expected, preload) do
    %TS{preload: preload, tests: add_test(code, expected, tests)}
  end

  defp split_tests([<< "$ iex ", rest :: binary >> | t], tests, code, [], _preload) do
    split_tests(t, tests, code, [], String.strip(rest))
  end

  defp split_tests([<< "iex>", rest :: binary >> | t], tests, code, [], preload) do
    split_tests(t, tests, [ strip(rest) | code ], [], preload)
  end

  defp split_tests([<< "iex>", rest :: binary >> | t], tests, code, expected, preload) do
    split_tests(t, add_test(code, expected, tests), [ strip(rest) ], [], preload)
  end

  defp split_tests([<< "...>", rest :: binary >> | t], tests, code, expected, preload) do
     split_tests(t, tests, [ strip(rest) | code ], expected, preload)
  end


  # Ignore comments
  defp split_tests( [ << "# ", _rest :: binary >> | t], tests, code, expected, preload) do
    split_tests(t, tests, code, expected, preload)
  end

  defp split_tests( [ "#" | t], tests, code, expected, preload) do
    split_tests(t, tests, code, expected, preload)
  end

  # This is where we pick up the expected output. The .. case is
  # continuation line
  defp split_tests( [ << ".. ", rest :: binary >> | t], tests, code, 
                    [ last_expected | expected ], preload) do
    split_tests(t, tests, code, [ "#{last_expected} #{strip(rest)}" | expected ], preload)
  end

  defp split_tests( [ value | t], tests, code, expected, preload) do
    split_tests(t, tests, code, [ strip(value) | expected ], preload)
  end



  defp add_test(code, expected, tests) do
    [ 
      %T{code: code |> remove_comments |> reverse, 
         expected: expected |> remove_trailing_blanks |> reverse}
      | tests 
    ]
  end

  defp remove_comments(code) do
    code |> map fn line -> Regex.replace(~r/\s*#\s.*/, line, "") end
  end

  defp remove_trailing_blanks([]),            do: []
  defp remove_trailing_blanks([ "" | rest ]), do: remove_trailing_blanks(rest)
  defp remove_trailing_blanks(other),         do: other

                                         
end

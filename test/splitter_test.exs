Code.require_file "test_helper.exs", __DIR__

defmodule SplitterTest do
  use    ExUnit.Case
  import IexTest.Splitter
  alias  IexTest.TestSequence, as: TS
  alias  IexTest.Test,         as: T

  test "splitting empty input returns nothing" do
    assert split_tests([]) == TS[preload: nil, tests: []]
  end

  test "preload is set if a $ iex line is given" do
    assert split_tests(["$ iex fred.ex"]) == TS[preload: "fred.ex", tests: []]
  end

  test "a single iex>/response pair is returned" do
    assert split_tests(["iex> 1+2", "3"]) == TS[preload: nil, tests: [ T[code: ["1+2"], expected: ["3"]] ]]
  end

  test "an iex> line with a continuation is handled" do
    assert split_tests(["iex> 1+", "...> 2", "3"]) == 
                       TS[preload: nil, 
                          tests: [ T[code: ["1+", "2"], expected: ["3"]]]]
  end

  test "a line with multiple lines of output is handled" do
    assert split_tests(["iex> 1+", "...> 2", "3", "4"]) == 
                        TS[preload: nil, 
                           tests: [ T[code: ["1+", "2"], expected: ["3", "4"]]]]
  end

  test "multiple tests are handled" do
    assert split_tests(["iex> 1+", "...> 0", "1", "iex> 2", "2"]) ==
                       TS[preload: nil, 
                          tests: [ T[code: [ "1+", "0" ], expected: ["1"]],
                                   T[code: ["2"],         expected: ["2"] ] ]]
  end

  test "multiple tests with preload are handled" do
    assert split_tests(["$ iex fred.ex", "iex> 1+", "...> 0", "1", "iex> 2", "2"]) ==
                       TS[preload: "fred.ex", 
                          tests: [ T[code: [ "1+", "0" ], expected: ["1"]],
                                   T[code: ["2"],         expected: ["2"]] ]]
  end

  test "comment is stripped from single line of code" do
    assert split_tests(["iex> 1+2 # a comment", "3"]) == TS[preload: nil, tests: [ T[code: ["1+2"], expected: ["3"]] ]]
  end

  test "comment is stripped from multiple lines of code" do
    assert split_tests(["iex> 1+ # a comment", "...> 2# and another", "3"]) == TS[preload: nil, tests: [ T[code: ["1+", "2"], expected: ["3"]] ]]
  end
end

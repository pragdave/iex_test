Code.require_file "test_helper.exs", __DIR__

defmodule RunnerTest do
  use    ExUnit.Case
  import Mock
  import IexTest.Runner

  import String, only: [strip: 1, split: 2]

  def sigil_l(lines, _opts) do
    lines |> strip |> split("\n") |> Enum.map(&strip/1)
  end

  test "empty parameters are successfully parsed" do
    params = parse_params("    ")
    assert length(params) == 0
  end

  test "non-empty params are successfully parsed" do
    params = parse_params(~s{in="a" test="no"})
    assert length(params) == 2
    assert Keyword.get(params, :in) == "a"
    assert Keyword.get(params, :test) == "no"
  end

  test "check_equal with two strings" do
    assert check_equal({"cat", "cat"}) == true
    assert check_equal({"cat", "dog"}) == false
  end

  test "check_equal with one string and one number" do
    assert check_equal({"1", 1}) == true
    assert check_equal({1, "1"}) == true
    assert check_equal({"1", 2}) == false
    assert check_equal({2, "1"}) == false
  end

  test "check_equal with elided start" do
    assert check_equal({"... some result", "this is some result"})
  end

  test "check equal with PID is successful" do
    assert check_equal({"Pid is #PID<3.4.5>", "Pid is #PID<7.8.99>"}) == true
  end

  test "check equal with Functions is successful" do
    assert check_equal({"Func #Function<23123>", "Func #Function<7.8.99>"}) == true
  end

  test "check_equal with floats is approximate" do
    assert check_equal({1.23, 1.2300003})
  end

  test "check_all_equal succeeds if all are equal" do
    assert check_all_equal([{"a", "a"}, {1, "1"}, {"2", 2}]) == true
  end

  test "check_all_equal fails if all are not equal" do
    assert check_all_equal([{"a", "a"}, {2, "1"}, {"2", 2}]) == false
  end

  test "report_result succeeds if expected == actual" do
    assert report_result("a.pml", 1, ["a"], ["a"], "code") == true
  end

  test "report_result succeeds if expected == actual with multiple lines" do
    assert report_result("a.pml", 1, ["a", "b"], ["a", "b"], "code") == true
  end

  test "report result ignores extra actual lines if expected ends ..." do
    assert report_result("a.pml", 1, ["a..."], ["a", "b"], "code") == true
  end

  test "report_result ignores extra actual lines if expected ends with ellipsis" do
    assert report_result("a.pml", 1, ["a…"], ["a", "b"], "code") == true
  end

  test "report_result reports error if expected and actual are different sizes" do
    with_mock IexTest.Runner, [:passthrough],
              [ report_error: fn("a.pml", 1, ["a"], ["a","b"], "code") -> :reported end ] do
      assert IexTest.Runner.report_result("a.pml", 1, ["a"], ["a", "b"], "code") == :reported
    end
  end

  test "runner runs single step" do 
    run_test ~l{
      iex> a = 1
      1
    }
  end

  test "runner runs two steps" do 
    run_test ~l{
      iex> a = 1
      1
      iex> b = 2
      2
    }
  end

  test "runner passes values from one step to the next" do 
    run_test ~l{
      iex> a = 1
      1
      iex> b = 2
      2
      iex> a + b
      3
    }
  end

  test "runner captures I/O" do
    run_test ~l{
      iex> IO.puts "hello"
      hello
      :ok
    }
  end

  test "runner catches exceptions" do
    run_test  ~l{
      iex> 1 / 0
      ** (ArithmeticError) bad argument in arithmetic expression
    }
  end

  test "returned lists are handled" do
  run_test ~l{
      iex> Enum.map [1,2,3,4], fn (n) -> n > 2 end
      [false, false, true, true]
    }
  end

  test "runner with I/O passes values to next" do
    run_test ~l{
      iex> a = IO.puts 1
      1
      :ok
      iex> a
      :ok
    }
  end

  test "runner can call faked iex functions" do
    run_test  ~l{
      iex> c("times.exs")
      [Times]
    }
  end

  defp run_test(lines) do
    ib = %IexTest.IexBlock{file_name: "a.pml", start_line: 1, params: ~s{in="test/code_to_load"}, lines: lines}
#    with_mock runner=IexTest.Runner, [:passthrough],
#      [ report_error: fn(_,expected,actual,_) -> raise "Report error called unexpectedly\nExpected: #{inspect expected}\nActual: #{inspect actual}" end] do
      IexTest.Runner.test_one_block(ib)
      #assert !called(runner.report_error)
#    end
  end

end

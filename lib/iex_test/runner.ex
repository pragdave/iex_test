defmodule IexTest.Runner do

  import IexTest.Splitter, only: [ split_tests: 1]
  import Enum,             only: [ join: 2, map: 2, reverse: 1 ]
  import String,           only: [ split: 2, strip: 1 ]

  alias  IexTest.TestSequence, as: TS
  alias  IexTest.Test,         as: T

  def test_blocks([]), do: []
  def test_blocks([h|t]) do
    test_one_block(h)
    test_blocks(t)
  end 

  defp test_one_block({file_name, params, content }) do
    params = parse_params(params)
    if Keyword.get(params, :test, "yes") != "no" do
      content 
      |> split(%r/\n/) 
      |> map(String.strip(&1))
      |> split_tests
      |> build_test_sequence(params)
      |> run_tests(file_name, params)
    end
  end

  defp build_test_sequence(TS[preload: nil, tests: tests], _params ) do
    build_tests(tests, [])
  end

  defp build_test_sequence(TS[preload: preload, tests: tests], params ) do
    in_dir = Keyword.get(params, :in, ".")
    loader = quote do
      Code.load_file(unquote(preload), unquote(in_dir))
    end
    build_tests(tests, [loader])
  end

  defp build_tests([], acc), do: reverse(acc)
  defp build_tests([ T[code: code, expected: expected] | tail ], acc) do
    debug("build tests", expected)
    build_tests(tail, [ build_test(code, expected) | acc ])
  end

  defp build_test(code, expected) do
    [ first | _ ] = expected
    generate_try_block = String.starts_with?(first, "**")

    res = generate_assertion_with_io(code, expected, generate_try_block)
#        res |> Macro.to_binary |> IO.puts 
    res
  end


  defp generate_assertion_with_io(code, expected, generate_try_block) do
    quote do
      code_ast = IexTest.Runner.to_value_ast(unquote(code), unquote(generate_try_block))
      output = ExUnit.CaptureIO.capture_io fn ->
        me <- { :value, Code.eval_quoted(code_ast, binding) }
      end

      value = receive do
         { :value, { value, binding }} -> [ value ]
      end

      if output, do: value = split(strip(output), "\n") ++ value
#      IO.puts "in test"
#      IO.inspect Enum.join(unquote(expected), "\n")
#      value = Enum.join(Enum.map(value, maybe_inspect(&1)), "\n")
#      IO.inspect value
#      expected = Enum.join(unquote(expected), "\n")
      IexTest.Runner.report_result(file_name, unquote(expected), value, unquote(code))
    end 
  end

  def maybe_inspect(val) when false, do: val
  def maybe_inspect(val),                     do: inspect(val)

  def to_value_ast(code, true) do
    ast = Code.string_to_ast!(code)
    quote hygiene: [ vars: false ] do 
      try do
        unquote(ast)
      rescue e -> 
        [ "** (#{inspect e.__record__(:name)}) #{e.message}" ]
      end
    end
  end 

  def to_value_ast(code, _) do
    ast = Code.string_to_ast!(code)
    quote hygiene: [ vars: false ] do 
      unquote(ast)
    end
  end 

  defp run_tests(tests, file_name, _params) do
    wrapper = quote do
      (fn ->
          import IexTest.Runner, only: [maybe_inspect: 1, to_value_ast: 2]
          me = self
          binding = []
          file_name = unquote(file_name)
          unquote_splicing(tests)
      end).()
    end
#    IO.puts(Macro.to_binary(wrapper))
    Code.eval_quoted(wrapper, file: file_name, line: tests.line_numberx)
  end



  def report_result(file_name, expected, actual, code) do
    debug("Report", expected, actual)

    cond do
      length(expected) != length(actual) -> 
        report_error(file_name, expected, actual, code)

      expected == actual ->
        true

      !(expected |> Enum.zip(actual) |> check_all_equal) ->
        report_error(file_name, expected, actual, code)

      true ->
        true
    end

  end

  def check_all_equal(list_of_expected_and_actual) do
    list_of_expected_and_actual
    |> map(function(check_equal/1))
    |> Enum.all?(&1)
  end

  def check_equal({expected, expected}), do: true
  def check_equal({expected, actual}) do
    cond do
      expected == inspect(actual) ->
        true

      Code.eval_string(expected) == actual ->
        true

      true ->
        false
    end 
  end

  defp remove_variable_terms(string) do
    string = Regex.replace(%r{#PID<[^>]+>}, string, "#PID<1.2.3>")
    Regex.replace(%r{#Function<[^>]+>}, string, "#Function<xxx>")
  end

  def report_result_real(file_name, expected, expected, code), do: []
  def report_error(file_name, expected, actual, code) do
    IO.puts "In code:  #{inspect code} [#{file_name}] "
    IO.puts "Expected: #{inspect expected}"
    IO.puts "But got:  #{inspect actual}\n"
  end


  defp parse_params(params) do
    Regex.scan(%r/(\w+)="([^"]*)"/, String.strip(params))
    |> map fn [k,v] -> {binary_to_atom(k),v} end
  end

  defp debug(_, _, _ // nil), do: nil

  defp debug(where, expected, actual // nil) do
    IO.puts "====== #{where}"
    expected |> map(IO.inspect(&1))
    if actual do
      IO.puts "--- actual"
      actual |> map(IO.inspect(&1))
    end
  end
end  
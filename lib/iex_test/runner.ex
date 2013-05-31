defmodule IexTest.Runner do

  import ExUnit.CaptureIO
  import IexTest.Splitter, only: [ split_tests: 1]
  import Enum, only: [ join: 2, map: 2, reverse: 1 ]
  import String, only: [ split: 2 ]

  def test_blocks([]), do: []
  def test_blocks([h|t]) do
    test_one_block(h)
    test_blocks(t)
  end 

  defp test_one_block({_file_name, params, content }) do
    content 
    |> split(%r/\n/) 
    |> map(String.strip(&1))
    |> split_tests
    |> build_test_sequence
    |> run_tests(params)
  end

  defp build_test_sequence({ _preload, tests } ), do: build_test_sequence(tests, [])

  defp build_test_sequence([], acc), do: reverse(acc)
  defp build_test_sequence([ { code, result } | tail ], acc) do
    build_test_sequence(tail, [ build_test(code, result) | acc ])
  end

  defp build_test(code, expected) do
    code_ast = code     |> Code.string_to_ast!
    expected = expected |> remove_pids 
    if !String.starts_with?(expected, "**") do
      expected = Code.string_to_ast!(expected)
    end

    IO.puts "Expected is #{inspect expected}"
    res = quote do
      value = unquote(code_ast)
      IexTest.Assert.assert_equal(value, unquote(expected))
    end 
#    res |> Macro.to_binary |> IO.puts 
    res
  end

  defp remove_pids(string) do
    Regex.replace(%r{#(\w+)<[^>]*>}, string, ":\\1")
  end


  defp run_tests(tests, _params) do
    wrapper = quote do
      (fn ->
          require IexTest.Assert

          unquote_splicing(tests)
      end).()
    end
    IO.puts(Macro.to_binary(wrapper))
    Code.eval_quoted(wrapper)
#    Enum.each tests, fn test -> IO.puts(Macro.to_binary(test)) end
  end



  def report_result(expected, actual, code) do
    report_result_real Regex.replace(%r{#PID<[^>]+>}, expected, "#PID<1.2.3>"),
                       Regex.replace(%r{#PID<[^>]+>}, actual,   "#PID<1.2.3>"),
                       code
  end

  def report_result_real(expected, expected, _code), do: []
  def report_result_real(expected, actual, code) do
    IO.puts "Expected: #{inspect expected}"
    IO.puts "Actual:   #{inspect actual}"
    IO.puts "In the following code:"
    IO.puts code
    IO.puts "--------------------------------------"
  end


  defp parse_params(params) do
    Regex.scan(%r/(\w+)="([^"]*)"/, String.strip(params))
    |> map fn [k,v] -> {binary_to_atom(k),v} end
  end

end  
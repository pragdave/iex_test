defmodule IexTest.Runner do

  import IexTest.Splitter, only: [ split_tests: 1]
  import Enum, only: [ join: 2, map: 2, reverse: 1 ]
  import String, only: [ split: 2, strip: 1 ]


  def test_blocks([]), do: []
  def test_blocks([h|t]) do
    test_one_block(h)
    test_blocks(t)
  end 

  defp test_one_block({file_name, params, content }) do
    params = parse_params(params)
    content 
    |> split(%r/\n/) 
    |> map(String.strip(&1))
    |> split_tests
    |> build_test_sequence(params)
    |> run_tests(file_name, params)
  end

  defp build_test_sequence({ nil, tests }, _params ) do
    build_tests(tests, [])
  end

  defp build_test_sequence({ preload, tests }, params ) do
    in_dir = Keyword.get(params, :in, ".")
    loader = quote do
      Code.load_file(unquote(preload), unquote(in_dir))
    end
    build_tests(tests, [loader])
  end

  defp build_tests([], acc), do: reverse(acc)
  defp build_tests([ { code, result } | tail ], acc) do
    build_tests(tail, [ build_test(strip(code), result) | acc ])
  end

  defp build_test(code, expected) do

    if length(expected) > 1 do
      expected = join expected, "\n"
      expected = [ "\"#{expected}\"" ]
    end

    expected = expected |> remove_pids |> Code.string_to_ast!

    res = if Regex.match?(%r{IO\.}, code) do
      generate_assertion_with_io(code, expected)
    else
      generate_assertion(code, expected)
    end
#    res |> Macro.to_binary |> IO.puts 
    res
  end


  defp generate_assertion(code, expected) do
    code_ast = code |> Code.string_to_ast!

    quote do
      value = unquote(code_ast)
      IexTest.Runner.report_result(file_name, unquote(expected), value, unquote(code))
    end 
  end

  defp generate_assertion_with_io(code, expected) do
    code_ast = code |> Code.string_to_ast!

    quote do
      output = ExUnit.CaptureIO.capture_io fn ->
        value = unquote(code_ast)
        me <- { :value, value }
      end

      value = receive do
         { :value, value } -> value
      end
      if output, do: value = join([ output, inspect(value) ], "")

      IexTest.Runner.report_result(file_name, unquote(expected), value, unquote(code))

    end 
  end

  defp remove_pids(string) do
    Regex.replace(%r{#(\w+)<[^>]*>}, string, ":\\1")
  end


  defp run_tests(tests, file_name, _params) do
    wrapper = quote do
      (fn ->
          require IexTest.Assert
          me = self
          file_name = unquote(file_name)
          unquote_splicing(tests)
      end).()
    end
    # IO.puts(Macro.to_binary(wrapper))
    Code.eval_quoted(wrapper)
  end



  def report_result(file_name, expected, actual, code) do

    report_result_real file_name,
                       Regex.replace(%r{#PID<[^>]+>}, inspect(expected), "#PID<1.2.3>"),
                       Regex.replace(%r{#PID<[^>]+>}, inspect(actual),   "#PID<1.2.3>"),
                       code
  end

  def report_result_real(_file_name, expected, expected, _code), do: []
  def report_result_real(file_name, expected, actual, code) do
    IO.puts "In code:  #{inspect code} [#{file_name}] "
    IO.puts "Expected: #{inspect expected}"
    IO.puts "But got:  #{inspect actual}\n"
  end


  defp parse_params(params) do
    Regex.scan(%r/(\w+)="([^"]*)"/, String.strip(params))
    |> map fn [k,v] -> {binary_to_atom(k),v} end
  end

end  
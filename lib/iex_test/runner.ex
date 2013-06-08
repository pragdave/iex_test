defmodule IexTest.Runner do

  import IexTest.Splitter, only: [ split_tests: 2]
  import Enum,             only: [ join: 2, map: 2, reverse: 1 ]
  import String,           only: [ split: 2, strip: 1 ]

  alias  IexTest.TestSequence, as: TS
  alias  IexTest.Test,         as: T
  alias  IexTest.IexBlock,     as: IB

  def test_blocks([]), do: []
  def test_blocks([h|t]) do
    test_one_block(h)
    test_blocks(t)
  end 

  defp test_one_block(IB[file_name: file_name, start_line: line_number, params: params, lines: lines]) do
    params = parse_params(params)
    if Keyword.get(params, :test, "yes") != "no" do
      lines 
      |> split_tests(line_number)
      |> build_test_sequence(params)
      |> run_tests(file_name, line_number, params)
    end
  end

  defp build_test_sequence(TS[preload: nil, tests: tests], params ) do
    build_tests(tests, [], params)
  end

  defp build_test_sequence(TS[preload: preload, tests: tests], params ) do
    in_dir = Keyword.get(params, :in, ".")
    loader = quote do
      Code.load_file(unquote(preload), unquote(in_dir))
    end
    build_tests(tests, [loader], params)
  end

  defp build_tests([], acc, _params), do: reverse(acc)
  defp build_tests([ T[code: code, expected: expected] | tail ], acc, params) do
    debug("build tests", expected)
    build_tests(tail, [ build_test(join(code, "\n"), expected, params) | acc ], params)
  end

  defp build_test(code, expected, params) do
    [ first | _ ] = expected
    generate_try_block = String.starts_with?(first, "**")

    res = generate_assertion_with_io(code, expected, generate_try_block, Keyword.get(params, :in, nil))
#        res |> Macro.to_binary |> IO.puts 
    res
  end


  defp generate_assertion_with_io(code, expected, generate_try_block, in_dir) do
    debug("generate", expected)
    quote(location: :keep) do
      try do
        code_ast = IexTest.Runner.to_value_ast(unquote(code), unquote(generate_try_block), unquote(in_dir))

        output = ExUnit.CaptureIO.capture_io fn ->
          me <- { :value, Code.eval_quoted(code_ast, binding, delegate_locals_to: IexTest.FakeIex) }
        end

        value = receive do
           { :value, { value, binding }} -> [ value ]
        end

        if output, do: value = split(strip(output), "\n") ++ value
        report_result(file_name, unquote(expected), value, unquote(code))
      rescue e ->
        IO.puts "Runtime error: #{e.message}"
        IO.puts unquote(code)
      end
    end 
  end


  def to_value_ast(code, generate_try_block = true, nil) do
    ast = Code.string_to_ast!(code)
    quote(hygiene: [ vars: false ], location: :keep) do 
      try do
        unquote(ast)
      rescue e -> 
        "** (#{inspect e.__record__(:name)}) #{e.message}"
      end
    end
  end 

  def to_value_ast(code, generate_try_block = true, in_dir) do
    ast = Code.string_to_ast!(code)
    quote(hygiene: [ vars: false ], location: :keep) do 
      try do
        File.cd!(unquote(in_dir), fn -> unquote(ast) end)
      rescue e -> 
        "** (#{inspect e.__record__(:name)}) #{e.message}"
      end
    end
  end 

  def to_value_ast(code, _, nil) do
    ast = Code.string_to_ast!(code)
    quote(hygiene: [ vars: false ], location: :keep) do 
      unquote(ast)
    end
  end 

  def to_value_ast(code, _, in_dir) do
    ast = Code.string_to_ast!(code)
    quote(hygiene: [ vars: false ], location: :keep) do 
      File.cd!(unquote(in_dir), fn ->  unquote(ast) end)
    end
  end 

  defp run_tests(tests, file_name, line_number, _params) do
    wrapper = quote(location: :keep) do
      fn ->
          import IexTest.Runner, only: [ to_value_ast: 3, report_result: 4]
          import IexTest.FakeIex

          me = self
          binding = []
          file_name = unquote(file_name)
          unquote_splicing(tests)
      end.()
    end
#        IO.puts(Macro.to_binary(wrapper))
    Code.compiler_options(ignore_module_conflict: true)
    Code.eval_quoted(wrapper, file: file_name, line: line_number, delegate_locals_to: IexTest.FakeIex)
  end



  def report_result(file_name, expected, actual, code) do
    debug("Report", expected, actual)

    unless is_list(expected) do
      raise "not list #{expected}"
    end

    # Allow for times where we only show the first line
    # of expected output

    if length(expected) == 1 do
      e = hd(expected)
      if String.ends_with?(e, ["...", "…"]) do
        actual = [ hd(actual) ]
        expected = [ Regex.replace(%r/\.\.\.$/, e, "") ]
      end
    end

    cond do
      length(expected) != length(actual) -> 
        report_error(file_name, expected, actual, code)

      expected == actual ->
        true

      (expected |> Enum.zip(actual) |> check_all_equal) ->
        true

      true ->
        report_error(file_name, expected, actual, code)
    end

  end

  def check_all_equal(list_of_expected_and_actual) do
    list_of_expected_and_actual
    |> Enum.map(function(check_equal/1))
    |> Enum.all?
  end

  def check_equal({expected, expected}), do: true
  def check_equal({expected, actual}) do
    cond do
      remove_hash_terms(expected) == remove_hash_terms(actual) ->
        true

      expected == inspect(actual) ->
        true

      Code.eval_string(expected) == actual ->
        true

      true ->
        false
    end 
  end

  defp remove_hash_terms(string) when !is_binary(string), do: remove_hash_terms(inspect string)

  defp remove_hash_terms(string) do
    str = Regex.replace(%r{#PID<[^>]+>}, string, "#PID<1.2.3>")
    res = Regex.replace(%r{#Function<[^>]+>}, str, "#Function<xxx>")
    res
  end

  # def type(v) when is_binary(v), do: type(v, "binary")
  # def type(v) when is_function(v), do: type(v, "function")
  # def type(v), do: type(v, "unknown")
  # def type(v, t) do
  #   IO.puts "#{t}: #{inspect v}"
  # end

  def report_result_real(_file_name, expected, expected, _code), do: []
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

  defp debugx(where, expected, actual // nil) do
    IO.puts "====== #{where}"
    expected |> map(IO.inspect(&1))
    if actual do
      IO.puts "--- actual"
      actual |> map(IO.inspect(&1))
    end
  end
end  
defmodule IexTest.Runner do

  import IexTest.Splitter, only: [ split_tests: 2]
  import Enum,             only: [ each: 2, join: 2, map: 2, reduce: 3 ]
  import String,           only: [ split: 2, trim: 1 ]

  alias  IexTest.TestSequence, as: TS
  alias  IexTest.Test,         as: T
  alias  IexTest.IexBlock,     as: IB

  @fake_functions (try do
                     import IexTest.FakeIex
                     dummy()
                     __ENV__.functions
                   rescue
                     _e -> 0  # do nothing
                   end)

  def test_blocks(blocks), do: each(blocks, &test_one_block/1)

  def test_one_block(%IB{file_name: file_name, start_line: line_number, params: params, lines: lines}) do
    params = parse_params(params)
    unless Keyword.get(params, :test, "yes") == "no" do
      lines 
      |> split_tests(line_number)
      |> run_tests(file_name, line_number, params)
    end
  end

  def run_tests(%TS{preload: preload, tests: tests}, file_name, line_number, params) do
    Code.compiler_options(ignore_module_conflict: true)
    if preload do
      in_dir = Keyword.get(params, :in, ".")
      IexTest.FakeIex.c(preload, in_dir)
    end
    reduce(tests, _binding=[], &run_one_test(&1, &2, file_name, line_number, params))
  end

  def run_one_test(%T{code: code, expected: expected}, binding, file_name, line_number, params) do
    me = self()
    in_dir = Keyword.get(params, :in, ".")
    
    output = ExUnit.CaptureIO.capture_io fn ->
      { actual, new_binding } = try do
                                  File.cd!(in_dir, fn -> 
                                    Code.eval_string(join(code, "\n"), binding, functions: @fake_functions)
                                  end)
                                rescue e ->
                                    { "** (#{inspect e.__struct__}) #{Exception.message(e)}", binding }
                                end
      send(me, { :result, [actual], new_binding })
    end

    receive do 
      { :result, actual, new_binding } ->
        actual = if output && String.length(output) > 0,
            do: split(trim(output), "\n") ++ actual,
            else: actual
        report_result(file_name, line_number, expected, actual, code)
        new_binding
    end
  end


  def report_result(file_name, line_number, expected, actual, code) 
  when is_list(expected) do

    # Allow for times where we only show the first line
    # of expected output

    { expected, actual } = normalize_expected(expected, actual)

    # (need __MODULE__ to make tests using :meck work. ugh)
    cond do
      length(expected) != length(actual) -> 
        __MODULE__.report_error(file_name, line_number, expected, actual, code)
        
      expected == actual ->
        true

      (expected |> Enum.zip(actual) |> check_all_equal) ->
        true

      true ->
        __MODULE__.report_error(file_name, line_number, expected, actual, code)
    end

  end

  defp normalize_expected(expected, actual) when length(expected) == 1 do
    e = hd(expected)
    if String.ends_with?(e, ["...", "…"]) do
      actual = [ hd(actual) ]
      expected = [ Regex.replace(~r/(…|\.\.\.)$/, e, "") ]
      { expected, actual }
    else
      { expected, actual }
    end
  end

  defp normalize_expected(expected, actual) do
    { expected, actual }
  end
    
  
  def check_all_equal(list_of_expected_and_actual) do
    list_of_expected_and_actual
    |> Enum.map(&check_equal/1)
    |> Enum.all?
  end

  def check_equal({expected, expected}), do: true
  def check_equal({expected, actual}) do
    # IO.inspect [ "check_equal", expected, actual ] 
    try do 
      cond do

        is_binary(expected) and is_binary(actual) and String.starts_with?(expected, "...") ->
        fake_expected = Regex.replace(~r{\.\.\.\s*}, expected, "")
        String.ends_with?(actual, fake_expected)

      # is_binary(expected) &&
      # is_binary(actual) &&
      # String.match?(expected, ~r/(\.\.\.|...)\s*$/) ->
      #   fake_expected = Regex.replace(~r{(\.\.\.\|…)s*$}, expected, "")
      #   raise inspect [:argh, fake_expected]
      #   String.starts_with?(actual, fake_expected)

        
      is_float(actual) ->
        expected = to_float(expected)
        abs(expected - actual) < (expected / 10_000)

      remove_hash_terms(expected) == remove_hash_terms(actual) ->
        true

      expected == inspect(actual) ->
        true

      is_binary(expected) and String.starts_with?(expected, "** ") ->
        false 
        
      {new_expected, _ } = Code.eval_string(expected) ->
          new_expected == actual

      end 
    rescue
      e ->
        IO.puts Exception.format(:error, e)
        IO.inspect [ e, expected, actual ]
        false
    end
  end


  defp remove_hash_terms(string) when is_binary(string) do
    string
    |> String.replace(~r{#PID<[^>]+>}, "#PID<1.2.3>")
    |> String.replace(~r{#Function<[.0-9]+}, "#Function<12.3456")
  end

  defp remove_hash_terms(string), do: remove_hash_terms(inspect string)

  def report_error(file_name, line_number, expected, actual, code) do
    IO.puts "In code:  #{inspect code} [#{file_name}:#{line_number}] "
    IO.puts "Expected: #{inspect expected}"
    IO.puts "But got:  #{inspect actual}\n"
  end


  def parse_params(params) do
    Regex.scan(~r/(\w+)="([^"]*)"/, String.trim(params))
    |> map(fn [_,k,v] -> {String.to_atom(k),v} end)
  end

  defp to_float(value) when is_binary(value) do
    String.to_float(value)
  end
  
  defp to_float(value) do
    value
  end
    
end  

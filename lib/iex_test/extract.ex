defmodule IexTest.Extract do

  import Enum, only: [ reverse: 1 ]

  @moduledoc """
  Given a list of file names, return a list of tuples:

  ~~~
  { file_name, params_to_iex_tag, code_within_block }
  ~~~

  """

  def iex_blocks([]), do: []
  def iex_blocks([h|t]) do
    [ extract_one_file(h) | iex_blocks(t)]
  end 

  defp extract_one_file(file_name) do
    File.read!(file_name) |> String.split("\n") |> extract_iex_blocks(file_name)
  end

  @doc false
  def extract_iex_blocks([], _file_name, _line_number,  acc), do: reverse(acc)

  def extract_iex_blocks([ line | rest ], file_name, line_number // 0,  acc // []) do
    if Regex.match?(%r{<iex([^>]*)>\s*$}, line) do
      { block, new_rest, new_line_number } = extract_one_block(rest, line_number+1, [])
      extract_iex_blocks(new_rest, file_name, new_line_number, [ block | acc ]) 
    else
      extract_iex_blocks(rest, file_name, line_number+1, acc)
    end 
  end 

  @doc false
  def extract_one_block([], _, _), do: raise("missing </iex>")
  def extract_one_block([ line | rest ], line_number, acc) do
    if line |> String.strip |> String.starts_with?("</iex>") do
      { reverse(acc), rest, line_number+1 }
    else  
      extract_one_block(rest, line_number+1, [ line | acc ])
    end 
  end
end
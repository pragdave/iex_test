defmodule IexTest.Extract do

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
    Regex.scan(%r{<iex([^>]*)>\s*\n(.*?)\n\s*</iex>}s, File.read!(file_name)) 
    |> Enum.map(fn [ params, code ] -> { file_name, params, code } end)
  end 
end
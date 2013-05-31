defmodule IexTest do

  def start(argv // System.argv) do
    IO.inspect self
    argv
    |> IexTest.Extract.iex_blocks
    |> List.flatten
    |> IexTest.Runner.test_blocks
    :ok
  end

end

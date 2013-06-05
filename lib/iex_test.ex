defmodule IexTest do

  def start(argv // System.argv) do
    argv
    |> IexTest.Extract.iex_blocks
    |> List.flatten
    |> IO.inspect
    |> IexTest.Runner.test_blocks
    :ok
  end

end

defmodule IexTest.FakeIex do

  @dir_key :iex_dir

  @moduledoc """
  Fake out the helpers from iex that our examples use.
  """
  def c(files), do: c(files, Process.get(@dir_key, "."))
  def c(files, path) do
    files
    |> List.wrap
    |> Enum.map(fn file -> "#{path}/#{file}" end)
    |> Kernel.ParallelCompiler.files
    |> Enum.map &elem(&1, 0)
  end 

  def cd(path) do
    Process.set(@dir_key, path)
  end

  def r(module) do
    if source = source(module) do
      { module, Code.load_file source }
    else
      :nosource
    end
  end

#  def raise(msg), do: Kernel.raise(msg)
#  def raise(msg, args), do: Kernel.raise(msg, args)

  defp source(module) do
    source = module.module_info(:compile)[:source]

    case source do
      { :source, source } -> String.from_char_list!(source)
      _ -> nil
    end
  end
end
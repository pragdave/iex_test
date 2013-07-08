defmodule IexTest.FakeIex do

  @dir_key :iex_dir

  @moduledoc """
  Fake out the helpers from iex that our examples use.
  """
  def c(files), do: c(files, Process.get(@dir_key, "."))
  def c(files, path) do
    tuples = Kernel.ParallelCompiler.files_to_path List.wrap(files), path
    Enum.map tuples, elem(&1, 0)
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

  def raise(msg), do: Kernel.raise(msg)
  def raise(msg, args), do: Kernel.raise(msg, args)

  defp source(module) do
    source = module.module_info(:compile)[:source]

    case source do
      { :source, source } -> list_to_binary(source)
      _ -> nil
    end
  end
end
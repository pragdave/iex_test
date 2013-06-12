
defmodule IexTest.Mixfile do
  use Mix.Project

  def project do
    [ app: :iex_test,
      version: "0.0.1",
      deps: deps(Mix.env) 
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      # mod: { IexTest, [] }
    ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }

  defp deps(:dev), do: deps(:test)
  defp deps(:test) do
    deps(:prod) ++ [ 
      { :meck, github: "eproxus/meck" },
      { :mock, github: "jjh42/mock" }
    ]

  end

  defp deps(:prod), do: []
end

defmodule IexTest.Assert do

  defmacro assert_equal(actual, expected) do
    quote do
      if unquote(actual) != unquote(expected) do
        raise "Expected #{Macro.to_binary(unquote(expected))}, got #{Macro.to_binary(unquote(actual))}"
      end
    end
  end

end

defmodule ExtractTest do
  use    ExUnit.Case
  import IexTest.Extract

  test "Extract one block finds end of block and updates line number" do
    lines = %W{
      one 
      two 
      three 
      </iex> 
      four 
      five}
    { block, rest, line_number } = extract_one_block(lines, 10, [])

    assert block == %W{ one two three }
    assert rest  == %W{ four five }
    assert line_number == 14
  end

  test "Extract blocks finds them" do
    lines = %W{
      one
      two
      <iex>
      three
      four
      </iex>
      five
      <iex>
      six
      </iex>
      seven}
    result = extract_iex_blocks(lines, "a.ex")
    assert result == [ %W{three four}, %W{six}]
  end
end
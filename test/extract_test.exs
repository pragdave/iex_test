defmodule ExtractTest do
  use    ExUnit.Case
  import IexTest.Extract

  alias IexTest.IexBlock, as: IB


  test "Extract one block finds end of block and updates line number" do
    lines = ~W{
      one 
      two 
      three 
      </iex> 
      four 
      five}
    { block, rest, line_number } = extract_one_block(lines, 10, [])

    assert block == ~W{ one two three }
    assert rest  == ~W{ four five }
    assert line_number == 14
  end

  test "Extract blocks finds them" do
    lines = ~W{
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
    b1 = IB.new(file_name: "a.ex", start_line: 4, params: "", lines: ~w{three four})
    b2 = IB.new(file_name: "a.ex", start_line: 9, params: "", lines: ~w{six})
    assert result == [ b1, b2 ]
  end

  test "parameters are picked up" do
    lines = [
      ~s{<iex p1="one" p2="two">},
      "line",
      "</iex>"
    ]
    [ result ] = extract_iex_blocks(lines, "a.ex")
    assert result.params == ~s{p1="one" p2="two"}
  end
end
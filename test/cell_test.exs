defmodule Propagator.CellTest do
  use ExUnit.Case, async: false
  alias Propagator.Cell

  test "ensure cells" do
    a1 = Cell.ensure_cell(:a)
    a2 = Cell.ensure_cell(:a)

    assert a1 == a2
  end

  test "add to cells" do
    a = Cell.ensure_cell(:a)

    Cell.add_content(a, 5, :alice)
    assert Cell.inspect_content(a) == {:content, 5, [:alice]}
    
    Cell.add_content(a, 5, :alice)
    assert Cell.inspect_content(a) == {:content, 5, [:alice]}
    
    Cell.add_content(a, 5, :bob)
    content = Cell.inspect_content(a)
    assert (case content do
	      {:content, 5, informants} ->
		Enum.member?(informants, :alice) and
		Enum.member?(informants, :bob) and
		length(informants) == 2
	      _ -> false
	    end)

    Cell.add_content(a, 7, :ruth)
    assert (Cell.inspect_content(a) |> Cell.contradiction?)
  end

  test "add contradiction" do
    a = Cell.ensure_cell(:a)
    Cell.add_content(a, 5, :bob)
    Cell.add_content(a, 7, :ruth)
    contradiction = Cell.get_content(a)

    assert contradiction |> Cell.contradiction?
    
    b = Cell.ensure_cell(:b)
    Cell.add_content(b, 1, :bob)
    assert (Cell.inspect_content(b) == {:content, 1, [:bob]})
    
    Cell.add_contradiction(b, contradiction)
    assert (Cell.inspect_content(b) |> Cell.contradiction?)

    c = Cell.ensure_cell(:c)
    Cell.add_contradiction(c, contradiction)
    assert(Cell.inspect_content(c) |> Cell.contradiction?)
  end
end

  

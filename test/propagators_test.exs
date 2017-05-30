defmodule Propagator.Functions do
  def plus(a, b) do
    a + b
  end
end

defmodule PropagatorsTest do
  use ExUnit.Case
  alias Propagator.Propagators, as: Prop
  alias Propagator.Cell
  
  test "simple add" do
    newPropPlus = Prop.function_to_propagator_constructor(&Propagator.Functions.plus/2)
    _propPlus = newPropPlus.([:a, :b, :c])

    assert(Cell.inspect_content(:a) == :nothing)
    
    Cell.add_content(:a, 1, :eli)
    Cell.add_content(:b, 3, :jenny)

    :timer.sleep(100)
    
    content = Cell.inspect_content(:c)

    assert (case content do
	      {:content, 4, informants} ->
		Enum.member?(informants, :eli) and
		Enum.member?(informants, :jenny) and
		length(informants) == 2
	      _ -> false
	    end)
  end
end

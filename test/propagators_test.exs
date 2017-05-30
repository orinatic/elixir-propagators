defmodule Propagator.Functions do
  def plus(a, b) do
    a + b
  end

  def minus(a, b) do
    a - b
  end
end

defmodule PropagatorsTest do
  use ExUnit.Case
  alias Propagator.Propagators, as: Prop
  alias Propagator.Cell
  
  test "directional add" do
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
    
    _secondPlus = newPropPlus.([:b,:c,:d])

    :timer.sleep(100)

    content = Cell.inspect_content(:d)
    
    assert (case content do
	      {:content, 7, informants} ->
		Enum.member?(informants, :eli) and
		Enum.member?(informants, :jenny) and
		length(informants) == 2
	      _ -> false
	    end)
  end

  test "constraint add" do
    newPropPlus = Prop.function_to_propagator_constructor(&Propagator.Functions.plus/2)
    newPropMinus = Prop.function_to_propagator_constructor(&Propagator.Functions.minus/2)

    _plus = newPropPlus.([:a, :b, :c])
    _minus1 = newPropMinus.([:c, :b, :a])
    _minus2 = newPropMinus.([:c, :a, :b])

    Cell.add_content(:b, 4, :eli)
    Cell.add_content(:c, 2, :eli)

    :timer.sleep(100)
    
    assert Cell.inspect_content(:a) == {:content, -2, [:eli]}
  end
end

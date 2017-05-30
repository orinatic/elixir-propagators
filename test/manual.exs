defmodule Propagator.Functions do
  def plus(a, b) do
    a + b
  end
end

alias Propagator.Propagators, as: Prop
alias Propagator.Cell

newPropPlus = Prop.function_to_propagator_constructor(&Propagator.Functions.plus/2)
propPlus = newPropPlus.([:a, :b, :c])

Cell.add_content(:a, 1, :eli)
Cell.add_content(:b, 3, :jenny)

Cell.get_content(:a)
Cell.get_content(:b)
Cell.get_content(:c)

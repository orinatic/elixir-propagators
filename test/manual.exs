defmodule KV.ManualTest do
  alias Propagator.Propagators, as: Prop
  plus = fn(a,b) -> a + b end
  newPropPlus = Prop.function_to_propagator_constructor(plus)
  propPlus = newPropPlus.([:a, :b, :c])
end

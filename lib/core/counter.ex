defmodule Propagator.Counter do
  def start_link(name) do
    Agent.start_link(fn -> %{} end, name: name)
  end

  def get_next(counter, name) do
    Agent.get_and_update(
      counter,
      fn(state) ->
	case Map.get(state, name) do
	  nil -> {0, Map.put(state, name, 1)}
	  n -> {n, Map.put(state, name, n + 1)}
	end
      end)
  end
end

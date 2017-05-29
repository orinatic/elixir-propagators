defmodule Propagator.Propagators do
  use GenServer
  alias Propagator.Cell

  ## Client API

  def function_to_propagator_constructor f do
    constructor = fn(cell_names) ->
      info = :erlang.fun_info(f)
      arity = info[:arity]
      name = info[:name]
      
      if length(cell_names) != (arity + 1) do
	raise "number of cells do not match function arity"
      end
      cells = cell_names |> Enum.map(&Cell.ensure_cell/1)
      
      {output, inputs} = List.pop_at(cells, length(cells) - 1)
      {:ok, _} = GenServer.start_link(__MODULE__, {info, inputs, output}, name: name)
      
      Enum.each(inputs, fn(input) -> Cell.add_output(input, name) end)
      alert_cell(name)
    end
    constructor
  end

  def alert_cell(cell) do
    GenServer.call(cell, {:cell_updated})
  end

  def alert_cells(cells) do
    Enum.each(cells, &alert_cell/1)
  end
  
  ## Server Callbacks
  
  def handle_call({:cell_updated}, _from, {f_info, inputs, output} = state) do
    input_contents = Enum.map(inputs, fn cell -> Cell.get_content(cell) end)

    contradictions = Enum.filter(input_contents, &Cell.contradiction?/1)
    
    cond do
      length(contradictions) > 0 ->
	Enum.each(contradictions, fn(contradiction) ->
	  Cell.add_contradiction(output, contradiction) end)
        {:reply, :ok, state}
      Enum.member?(input_contents, :nothing) ->
	{:reply, :ok, state}
      true ->
	informants = Enum.map(input_contents, &Cell.get_informant/1)
	infos = Enum.map(input_contents, &Cell.get_info/1)
	value = apply(f_info[:module], f_info[:name], infos)
	Cell.add_content(output, value, informants)
	{:reply, :ok, state}
    end
  end

  def handle_call(msg, from, state) do
    raise "unhandled call msg: #{inspect msg}, from: #{inspect from}, state: #{inspect state} for Propagator.Propagators"
  end

end

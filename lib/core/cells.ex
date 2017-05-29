defmodule Propagator.Cell do
  use GenServer
  alias Propagator.Propagators, as: Prop
  ## Utility functions

  def contradiction?(content) do
    case content do
      {:contradiction, _, _} -> true
      _ -> false
    end
  end

  def get_informant({:content, _, informants}) do
    informants
  end

  def get_info({:content, info, _}) do
    info
  end
  
  ## Client API    

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end
  
  def add_content(cell, info, informants) do
    GenServer.cast(cell, {:add_content, info, informants})
  end

  def add_contradiction(cell, contradiction) do
    GenServer.cast(cell, {:add_contradiction, contradiction})
  end

  def add_output(cell, output) do
    GenServer.call(cell, {:add_output, output})
  end

  def get_content(cell) do
    GenServer.call(cell, {:content})
  end

  def ensure_cell(cell) do
    case start_link(cell) do
      {:ok, _pid} -> cell
      {:error, {:already_started, _pid}} -> cell
      {:error, err} -> raise "Failed to ensure cell #{cell}: #{err}"
    end
  end
    
  ## Server Callbacks

  def init(:ok) do
    outputs = MapSet.new()
    content = :nothing
    {:ok, {outputs, content}}
  end

  # Handle Call blocks and waits for a return
  def handle_call({:content}, _from, {_, content} = state) do
    {:reply, content, state}
  end

  def handle_call({:outputs}, _from, {{_, outputs}, _} = state) do
    {:reply, outputs, state}
  end

  # Caller should make sure to update itself after calling this
  def handle_call({:add_output, new_output}, _from, {outputs, content} = state) do
    if(MapSet.member?(outputs, new_output)) do
      {:reply, :ok, state}
    else
      {:reply, :ok, {MapSet.put(outputs, new_output), content}}
    end
  end
  
  # Needs to handle merging, once I add intervals
  # Handle_cast does not wait for a return
  def handle_cast({:add_content, new_info, new_informants}, {outputs, content} = state) do
    case content do
      {:content, info, informants} when info == new_info ->
	if(MapSet.subset?(new_informants, informants)) do
	  {:noreply, state}
	else
	  Prop.alert_cells(outputs)
	  {:noreply, {outputs, {:content, info, MapSet.union(new_informants, informants)}}}
	end
      {:content, info, informants} ->
	{:noreply, outputs, {:contradiction, [{info, informants}, {new_info, new_informants}]}}
      :nothing ->
	Prop.alert_cells(outputs)
        {:noreply, {outputs, {:content, new_info, new_informants}}}
      {:contradiction, _contradictions} ->
	{:noreply, state}
    end
  end
  
  def handle_cast({:add_contradiction, {c1, c2}}, {outputs, content} = state) do  
    case content do
      {:contradiction, cs} ->
	unless(Enum.member?(cs, {c1, c2}) or Enum.member?(cs, {c2, c1})) do
	  Prop.alert_cells(outputs)
	  {:noreply, {outputs, {:contradiction, [{c1, c2}| cs]}}}
	else
	  {:noreply, state}
	end
      _ ->
	{:noreply, state}
    end
  end

  def handle_cast(msg, state) do
    raise "unhandled cast: #{msg}"
    state
  end
	
	
end

  

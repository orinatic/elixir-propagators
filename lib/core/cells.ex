defmodule Propagator.Cell do
  use GenServer
  alias Propagator.Propagators, as: Prop
  ## Utility functions

  def contradiction?(content) do
    case content do
      {:contradiction, _} -> true
      _ -> false
    end
  end

  def get_informant({:content, _, informants}) do
    informants
  end

  def get_info({:content, info, _}) do
    info
  end
  
  def inspect_content(cell) do
    case get_content(cell) do
      {:content, info, informants} -> {:content, info, MapSet.to_list(informants)}
      otherwise -> otherwise
    end
  end
  
  ## Client API    

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end
  
  def add_content(cell, info, informants) do
    send_informants = case informants do
			%MapSet{} -> informants
			[_] -> MapSet.new(informants)
			_ -> MapSet.new([informants])
		      end
      GenServer.cast(cell, {:add_content, info, send_informants})
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
  
  defp alert_outputs() do
    IO.puts "alerting outputs"
    this = self()
    spawn_link fn -> GenServer.cast(this, {:notify_outputs}) end
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

  def handle_cast({:notify_outputs}, {outputs, content}) do
    IO.puts "spawning func to alert cells"
    spawn_link fn -> Prop.alert_cells(outputs) end
    {:noreply, {outputs, content}}
  end
    
  
  # Needs to handle merging, once I add intervals
  # Handle_cast does not wait for a return
  def handle_cast({:add_content, new_info, new_informants}, {outputs, content} = state) do
    case content do
      {:content, info, informants} when info == new_info ->
	if(MapSet.subset?(new_informants, informants)) do
	  {:noreply, state}
	else
	  alert_outputs()
	  {:noreply, {outputs, {:content, info, MapSet.union(new_informants, informants)}}}
	end
      {:content, info, informants} ->
	{:noreply, {outputs, {:contradiction, [{info, informants}, {new_info, new_informants}]}}}
      :nothing ->
	IO.puts "coming up from nothing. Outputs are #{inspect outputs}"
	alert_outputs()
        {:noreply, {outputs, {:content, new_info, new_informants}}}
      {:contradiction, _contradictions} ->
	{:noreply, state}
    end
  end
  
  def handle_cast({:add_contradiction, {:contradiction, new_cs}}, {outputs, content} = state) do  
    case content do
      {:contradiction, cs} ->
	if(length(Enum.uniq(cs ++ new_cs)) != length(cs)) do
	  alert_outputs()
	  {:noreply, {outputs, {:contradiction, Enum.uniq(cs ++ new_cs)}}}
	else
	  {:noreply, state}
	end
      _ ->
	alert_outputs()
	{:noreply, {outputs, {:contradiction, new_cs}}}
    end
  end

  def handle_cast(msg, state) do
    raise "unhandled cast: #{msg}"
    state
  end
	
	
end

  

defmodule Propagator.Cell do
  use GenServer

  ## Client API

  #TODO

  ## Server Callbacks

  def init() do
    neighbors = []
    content = :nothing
    {:ok, {neighbors, content}}
  end

  # Handle Call blocks and waits for a return
  def handle_call({:content}, _from, {_, content} = state) do
    {:reply, content, state}
  end
  
  def handle_cast({:add_content, new_content, informant}, _from, {neighbors, content} = state) do
    merged_content = merge_content(new_content, content)
    cond do
      merged_content == content ->
	{:noreply, state}
	

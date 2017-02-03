defmodule Drab.Store do
  @moduledoc false

  defstruct commander: nil, 
            store_pid: nil

  use GenServer

  def start_link(commander_and_store) do
    GenServer.start_link(__MODULE__, commander_and_store)
  end

  @doc false
  def handle_cast({:put_store, key, value}, {commander, store}) do
    {:noreply, {commander, Map.merge(store, %{key => value})}}
  end

  @doc false
  def handle_call(:get_store, _from, {commander, store}) do
    {:reply, store, {commander, store}}
  end

  @doc false
  def handle_call({:get_store, key}, _from, {commander, store}) do
    {:reply, store[key], {commander, store}}
  end
end

defmodule Drab.Store do
  @moduledoc false

  defstruct commander: nil, 
            store_pid: nil

  use GenServer

  def start_link(store) do
    GenServer.start_link(__MODULE__, store)
  end

  @doc false
  def handle_cast({:put_store, key, value}, store) do
    {:noreply, Map.merge(store, %{key => value})}
  end

  @doc false
  def handle_call(:get_store, _from, store) do
    {:reply, store, store}
  end

  @doc false
  def handle_call({:get_store, key}, _from, store) do
    {:reply, store[key], store}
  end
end

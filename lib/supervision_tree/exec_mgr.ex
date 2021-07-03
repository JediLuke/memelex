defmodule Memex.Env.ExecutiveManager do
  use GenServer
  require Logger


  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: Memex.Env.ExecMgr)
  end


  @impl GenServer
  def init(env) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, env, {:continue, :load_memex_from_disk}}
  end


  @impl GenServer
  def handle_continue(:load_memex_from_disk, state) do


    Memex.Env.WikiManager.start_link(state)
    {:noreply, state}
  end


end
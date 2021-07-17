defmodule Memex.Agents.BackupAgent do
  use GenServer
  require Logger
  alias Memex.Utils
 
  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end


  @impl GenServer
  def init(_params) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, %{}, {:continue, :boot_sequence}}
  end

  @impl GenServer
  def handle_continue(:boot_sequence, state) do
    IO.puts "BACKUP AGENT IS RUNNING"
    {:noreply, state}
  end

end
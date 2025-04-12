defmodule Memelex.LLModels.AsyncBooter do
  @moduledoc """
  This GenServer only exists so that we start these Nx Serving processes
  asynchronously, so that we don't block the main supervision tree from booting.
  """
  use GenServer
  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    # Set the process flag to trap exits
    Process.flag(:trap_exit, true)

    {:ok, %{}, {:continue, :boot_async}}
  end

  def handle_continue(:boot_async, state) do
    Logger.debug("#{__MODULE__} starting asynchronous LLM servers...")
    Memelex.LLModels.Supervisor.start_link([])

    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.warn("Memelex.LLModels.Supervisor exited with reason: #{inspect(reason)}")
    # Take any necessary action here, such as restarting the process or alerting someone
    {:noreply, state}
  end
end

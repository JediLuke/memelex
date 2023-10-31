defmodule Memelex.LLModels.AsyncBooter do
  @moduledoc """
  This GenServer only exists so that we start these Nx Serving processes
  asyncronously, so that we don't block the main supervision tree from booting.
  """
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{}, {:continue, :boot_async}}
  end

  def handle_continue(:boot_async, state) do
    # Here, you can boot other processes or do any setup you want
    # without blocking the main supervision tree
    {:ok, _pid} = Memelex.LLModels.Supervisor.start_link([])

    {:noreply, state}
  end
end

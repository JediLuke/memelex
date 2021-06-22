defmodule Memex.BootCheck do
  use GenServer
  require Logger


  def start_link(params)  do
    GenServer.start_link(__MODULE__, params)
  end


  @impl GenServer
  def init(_params) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, %{}, {:continue, :check_for_memex_environment}}
  end

  @impl GenServer
  def handle_continue(:check_for_memex_environment, state) do
    Logger.debug "Checking for an existing Memex environment..."

    if existing_memex_environment_detected?() do
      load_existing_memex_environment()
      {:noreply, state}
    else
      raise "can't create new Memex files yet"
      {:noreply, state}
    end
  end


  defp existing_memex_environment_detected?() do
    "./jediluke.memex-env" |> File.exists?()
  end

  defp load_existing_memex_environment() do
    Logger.info "Loading `Jediluke` environment..."
    :ok
  end
end
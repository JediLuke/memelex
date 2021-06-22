defmodule Memex.BootCheck do
  use GenServer
  require Logger
  alias Memex.Utils

  #@memex_environment_file "./environments/jediluke.memex-env"
  @memex_environment_file "./environments/sample.memex-env"

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

    if existing_memex_environment_detected?(@memex_environment_file) do
      load_existing_memex_environment()
      {:noreply, state}
    else
      create_new_memex_environment()
      {:noreply, state}
    end
  end


  defp existing_memex_environment_detected?(nil), do: false
  defp existing_memex_environment_detected?(filepath) when is_bitstring(filepath) do
    filepath |> File.exists?()
  end
  defp existing_memex_environment_detected?(_else), do: false

  defp load_existing_memex_environment() do
    env_map = Utils.FileIO.readmap(@memex_environment_file)
    Logger.info "Loading `#{env_map["name"]}` environment..."
    :ok
  end

  defp create_new_memex_environment() do
    Logger.debug "creating a new Memex environment..."

    ##TODO ideally I would like to get the User to input a name
    #      here, unfortunately, that was tricker than I would like...

    new_env_map  = %{"name" => "my_env"}
    new_env_file = "./environments/#{new_env_map["name"]}.memex-env"

    Utils.FileIO.writemap(new_env_file, new_env_map)
    Logger.info "Loading `#{new_env_map["name"]}` environment..."
    :ok
  end
end
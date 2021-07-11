defmodule Memex.BootCheck do
  use GenServer
  require Logger
  alias Memex.Utils
 
  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end


  @impl GenServer
  def init(_params) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, %{}, {:continue, :check_for_memex_environment}}
  end

  @impl GenServer
  def handle_continue(:check_for_memex_environment, state) do
    
    env = Application.get_env(:memex, :environment)

    case probe(env) do
      :new_environment ->
         # changing this to raise because otherwise we might make some weird directories on peoples Windows boxes :D
         raise "Could not detect a Memex directory: #{inspect env.memex_directory}"
      :existing_environment ->
         load_existing_memex(env)
         {:noreply, state}
      :invalid_environment_config ->
         raise "attempted to boot without a valid environment configured"
    end
  end

  def probe(%{name: name, memex_directory: dir} = env)
    when is_bitstring(name) and is_bitstring(dir) do
      if File.exists?(dir) do
        explore_memex_directory(env)
      else
        :new_environment
      end
  end

  def probe(_invalid_env) do
    :invalid_environment_config
  end

  def explore_memex_directory(env) do
    # look for whoami doc, check it matches the env.name
    # look for tidbit.js
    # look for journal directory
    :existing_environment #TODO so right now, this just checks if the memex directory exists
  end

  def start_new_memex(env) do
    Logger.info "No `#{env.name}` environment..."
    Logger.info "Creating new memex directory: #{env.memex_directory}..."

    :ok = File.mkdir_p!(env.memex_directory)
    Memex.EnvironmentSupervisor.start_link(env)
  end

  def load_existing_memex(env) do
    Logger.info "Detected `#{env.name}` environment..."
    Memex.EnvironmentSupervisor.start_link(env)
  end
end
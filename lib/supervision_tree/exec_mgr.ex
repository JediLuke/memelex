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
    Memex.Env.PasswordManager.start_link(state)
    GenServer.cast(self(), :reload_the_custom_environment_elixir_modules)
    {:noreply, state}
  end

  #TODO this has to be attempted in a seperate task, since if the environment
  #     module has errors this brings down the whole sup tree

  @impl GenServer
  def handle_cast(:reload_the_custom_environment_elixir_modules, state) do
    plugin_file = state.memex_directory <> "/my_customizations.ex"
    IO.inspect plugin_file
    IEx.Helpers.c plugin_file
    {:ok, custom_module} = Memex.Environment.Customizations.on_boot()
    {:noreply, state |> Map.merge(%{ex_module: custom_module})} # this environment's custom Elixir module
  end

end
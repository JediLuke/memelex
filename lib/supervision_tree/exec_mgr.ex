defmodule Memex.Env.ExecutiveManager do
  use GenServer
  require Logger


  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end


  @impl GenServer
  def init(env) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, env, {:continue, :load_memex_from_disk}}
  end


  @impl GenServer
  def handle_continue(:load_memex_from_disk, state) do
    #TODO put these under another Supervisor
    Memex.Env.WikiManager.start_link(state)
    Memex.Env.PasswordManager.start_link(state)
    make_environment_directories(state)
    GenServer.cast(self(), :reload_the_custom_environment_elixir_modules)
    {:noreply, state}
  end

  #TODO this has to be attempted in a seperate task, since if the environment
  #     module has errors this brings down the whole sup tree

  #TODO reload all custom agents here aswell

  @impl GenServer
  def handle_cast(:reload_the_custom_environment_elixir_modules, %{ex_module: mod} = state) do
    IEx.Helpers.r mod
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:reload_the_custom_environment_elixir_modules, state) do
    plugin_file = state.memex_directory <> "/my_customizations.ex"
    if File.exists?(plugin_file) do
      IEx.Helpers.c plugin_file
      {:ok, custom_module} = Memex.Environment.Customizations.on_boot() #NOTE: This module is/must be defined in the `my_customizations.ex` file, which is what we're reloading
      {:noreply, state |> Map.merge(%{ex_module: custom_module})} # this environment's custom Elixir module
    else
      Logger.warn "No Customizations found for this environment..."
      {:noreply, state}
    end
  end

  def make_environment_directories(%{memex_directory: dir}) do
    :ok = File.mkdir_p(dir <> "/images")
    :ok = File.mkdir_p(dir <> "/docs")
    :ok = File.mkdir_p(dir <> "/text_snippets")
  end

end
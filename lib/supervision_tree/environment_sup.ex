defmodule Memelex.EnvironmentSupervisor do
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

      build_environment(state)

      # Memelex.Env.WikiManager.start_link(state)
      # Memelex.Env.PasswordManager.start_link(state)
      GenServer.cast(self(), :reload_custom_elixir_module)

      {:noreply, state}
   end

  #TODO this has to be attempted in a seperate task, since if the environment
  #     module has errors this brings down the whole sup tree

  #TODO reload all custom agents here aswell

   def handle_call(:who_am_i?, _from, state) do
      {:reply, {:ok, state.name}, state}
   end

#   def handle_call(:fetch_custom_menu, _from, state) do
#     plugin_file = state.memex_directory <> "/my_customizations.ex"
#     if File.exists?(plugin_file) do
#       IEx.Helpers.c plugin_file
#       custom_menu = Memelex.Environment.Customizations.custom_menu() #NOTE: This module is/must be defined in the `my_customizations.ex` file, which is what we're reloading
#       {:reply, {:ok, custom_menu}, state}
#     else
#       Logger.warn "No Customizations found for this environment..."
#       {:reply, {:error, "No Customizations found for this environment."}, state}
#     end
#   end

   @impl GenServer
   def handle_cast(:reload_custom_elixir_module, %{modz_module: mod} = state) do
      IEx.Helpers.r mod
      {:noreply, state}
   end

   @impl GenServer
   def handle_cast(:reload_custom_elixir_module, state) do
      plugin_file = state.memex_directory <> "/my_modz.ex"
      if File.exists?(plugin_file) do
         Logger.info "Loading customizations from #{plugin_file}..."
         new_state = load_customizations(state, plugin_file)
         {:noreply, new_state}
      else
         Logger.warn "No Customizations found for this environment..."
         {:noreply, state}
      end
   end

   def build_environment(%{memex_directory: dir}) do
      :ok = File.mkdir_p(dir <> "/images")
      :ok = File.mkdir_p(dir <> "/docs")
      :ok = File.mkdir_p(dir <> "/textfiles")
   end

   def load_customizations(state, modz_file) do

      #TODO import all these functions automatically
      IEx.Helpers.c modz_file

      #TODO check if this function is exported, and only run it if it is
      case Memelex.My.Modz.on_boot() do #NOTE: This module is/must be defined in the `my_customizations.ex` file, which is what we're reloading
         :ok ->
               #TODO if I had a behaviour/macro, which automatically added
               # some callbacks to fetch a custom module name, we could do that...
               # but honestly I think this is probably easier. Though it may
               # stop us from loading multiple Memex environments simultaneously,
               # though that doesn't sound desirable anyway
               state |> Map.merge(%{modz_module: Memelex.My.Modz})
         error ->
               Logger.error "Failed to load Customizations, `on_boot` returned: #{inspect error}"
               state
      end
   end

end
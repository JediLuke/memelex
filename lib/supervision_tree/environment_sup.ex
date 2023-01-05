defmodule Memelex.Environment do
  use GenServer
  require Logger


   def start_link(params)  do
      GenServer.start_link(__MODULE__, params, name: __MODULE__)
   end

   #TODO rename `memex_directory` to somthing else


   @impl GenServer
   def init(memex_env) do
      Logger.info "#{__MODULE__} initializing..."
      {:ok, memex_env, {:continue, :load_memex_from_disk}}
   end


   @impl GenServer
   def handle_continue(:load_memex_from_disk, memex_env) do

      build_environment(memex_env)

      Memelex.WikiServer.start_link(memex_env)
      # Memelex.Env.PasswordManager.start_link(memex_env)

      GenServer.cast(self(), :reload_custom_elixir_module)

      {:noreply, memex_env}
   end

  #TODO this has to be attempted in a seperate task, since if the environment
  #     module has errors this brings down the whole sup tree

  #TODO reload all custom agents here aswell

   def handle_call(:who_am_i?, _from, memex_env) do
      {:reply, {:ok, memex_env.name}, memex_env}
   end

#   def handle_call(:fetch_custom_menu, _from, memex_env) do
#     plugin_file = memex_env.memex_directory <> "/my_customizations.ex"
#     if File.exists?(plugin_file) do
#       IEx.Helpers.c plugin_file
#       custom_menu = Memelex.Environment.Customizations.custom_menu() #NOTE: This module is/must be defined in the `my_customizations.ex` file, which is what we're reloading
#       {:reply, {:ok, custom_menu}, memex_env}
#     else
#       Logger.warn "No Customizations found for this environment..."
#       {:reply, {:error, "No Customizations found for this environment."}, memex_env}
#     end
#   end

   @impl GenServer
   def handle_cast(:reload_custom_elixir_module, %{modz_module: mod} = memex_env) do
      IEx.Helpers.r mod
      {:noreply, memex_env}
   end

   @impl GenServer
   def handle_cast(:reload_custom_elixir_module, memex_env) do
      modz_file = memex_env.memex_directory <> "/my_modz.ex"
      if File.exists?(modz_file) do
         Logger.info "Loading customizations from #{modz_file}..."
         new_memex_env = load_customizations(memex_env, modz_file)
         {:noreply, new_memex_env}
      else
         Logger.warn "No Customizations found for this environment..."
         {:noreply, memex_env}
      end
   end

   def build_environment(%{memex_directory: dir}) do
      :ok = File.mkdir_p(dir <> "/images")
      :ok = File.mkdir_p(dir <> "/docs")
      :ok = File.mkdir_p(dir <> "/textfiles")
   end

   def load_customizations(memex_env, modz_file) do

      #TODO import all these functions automatically
      IEx.Helpers.c modz_file

      #TODO check if this function is exported, and only run it if it is
      case Memelex.My.Modz.on_boot(memex_env) do #NOTE: This module is/must be defined in the `my_customizations.ex` file, which is what we're reloading
         :ok ->
               #TODO if I had a behaviour/macro, which automatically added
               # some callbacks to fetch a custom module name, we could do that...
               # but honestly I think this is probably easier. Though it may
               # stop us from loading multiple Memex environments simultaneously,
               # though that doesn't sound desirable anyway
               memex_env |> Map.merge(%{modz_module: Memelex.My.Modz})
         error ->
               Logger.error "Failed to load Customizations, `on_boot` returned: #{inspect error}"
               memex_env
      end
   end

end
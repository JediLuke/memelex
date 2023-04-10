defmodule Memelex.Environment do
  use GenServer
  require Logger


  # This is the filename we will look for when looking for an Environment specific custom ELixir module
  @my_modz "/my_modz.ex"

  


  #TODO this has to be attempted in a seperate task, since if the environment
  #     module has errors this brings down the whole sup tree

  #TODO reload all custom agents here aswell




   def start_link(params)  do
      GenServer.start_link(__MODULE__, params, name: __MODULE__)
   end

   def new_modz_file(env_name) do
      new_my_modz = Memelex.Utils.GenerateMyModz.new(%{name: env_name})
      Memelex.Utils.FileIO.write(my_modz_file(), new_my_modz)
   end

   def reload_modz do
      GenServer.cast(__MODULE__, :reload_modz)
   end

   def my_modz_file do
      {:ok, memex_dir} = GenServer.call(__MODULE__, :get_memex_dir)
      memex_dir <> @my_modz
   end

   @impl GenServer
   def init(%{
      name: _memex_environment_name,
      memex_directory: _memex_dir
   } = memex_env) do
      Logger.info "#{__MODULE__} initializing..."
      {:ok, memex_env, {:continue, :load_memex_from_disk}}
   end


   @impl GenServer
   def handle_continue(:load_memex_from_disk, memex_env) do

      build_environment(memex_env)

      Memelex.WikiServer.start_link(memex_env)
      # Memelex.Env.PasswordManager.start_link(memex_env)

      #TODO check for backups directory, look in memex for backups records

      reload_modz()

      GenServer.cast(__MODULE__, :on_boot)


      {:noreply, memex_env}
   end

   def handle_call(:who_am_i?, _from, memex_env) do
      {:reply, {:ok, memex_env.name}, memex_env}
   end

   def handle_call(:get_memex_dir, _from, memex_env) do
      {:reply, {:ok, memex_env.memex_directory}, memex_env}
   end

   # @impl GenServer
   # def handle_cast(:reload_modz, %{modz_module: mod} = memex_env) do
   #    IEx.Helpers.r mod
   #    {:noreply, memex_env}
   # end

   @impl GenServer
   def handle_cast(:reload_modz, memex_env) do
      modz_file = memex_env.memex_directory <> "/my_modz.ex"

      if File.exists?(modz_file) do
         reload_modz_file(memex_env, modz_file)
      else
         Logger.warn "No Customizations found for this environment..."
         #TODO create a new my_modz.ex, or jediluke.ex or whatever, file
      end

      {:noreply, memex_env}
   end

   def handle_cast(:on_boot, memex_env) do
      # #TODO check if this function is exported, and only run it if it is
      # case Memelex.My.Modz.on_boot(memex_env) do #NOTE: This module is/must be defined in the `my_customizations.ex` file, which is what we're reloading
      #    :ok ->
      #          #TODO if I had a behaviour/macro, which automatically added
      #          # some callbacks to fetch a custom module name, we could do that...
      #          # but honestly I think this is probably easier. Though it may
      #          # stop us from loading multiple Memex environments simultaneously,
      #          # though that doesn't sound desirable anyway
      #          memex_env |> Map.merge(%{modz_module: Memelex.My.Modz})
      #    error ->
      #          Logger.error "Failed to load Customizations, `on_boot` returned: #{inspect error}"
      #          memex_env
      # end
      {:noreply, memex_env}
   end


   def build_environment(%{memex_directory: dir}) do
      :ok = File.mkdir_p(dir <> "/images")
      :ok = File.mkdir_p(dir <> "/docs")
      :ok = File.mkdir_p(dir <> "/textfiles")
   end

   def reload_modz_file(memex_env, modz_file) do
      Logger.info "Loading customizations from #{modz_file}..."


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



            #TODO custom menu items should be part of each individual Memex

      #TODO reloading this should also update all custom menus, maybe we need to broadcast it out, like a :custom_reloadz topic or something


       #TODO try to load & compile this file, handle failure if it doesn't compile...

      #TODO import all these functions automatically
      IEx.Helpers.c modz_file
      IEx.Helpers.r(Memelex.My.Modz)

   end

end
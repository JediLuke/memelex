defmodule Memelex.BootLoader do
   use GenServer
   require Logger

   def start_link(params)  do
      GenServer.start_link(__MODULE__, params, name: __MODULE__)
   end
  
   @impl GenServer
   def init(env) do
      Logger.info "#{__MODULE__} initializing..."

      #REMINDER: By default, Flamelex boots with the memelex config [active?: false]
      case Application.get_env(:memelex, :active?) do
         false ->
            Logger.warn "Memelex booted into mode: `:inactive` -- not starting the Memelex."
            {:ok, %{}}
         _otherwise ->
            {:ok, %{}, {:continue, :check_for_memex_environment}}
      end
   end

   @impl GenServer
   def handle_continue(:check_for_memex_environment, state) do
      env = Application.get_env(:memelex, :environment)
      probe(env)
      {:noreply, state}
   end
 
   def probe(%{name: name, memex_directory: dir} = env)
      when is_bitstring(name) and is_bitstring(dir) do
         if File.dir?(dir) do
            load_existing_memex(env)
         else
            # start_new_memex(env)
            stop_boot("""
            The Memex directory defined in `config.exs` does not exist.

            The directory #{inspect dir} does not exist. Please create it before running the Memelex. For example, on Linux:

            mkdir -p #{dir}

            Note that the full path must be declared in the config.

            As we cannot continue, Memelex will now exit. Once you have performed the necessary config changes, simply restart the Memex and try again.
            """)
         end
   end
 
   def probe(_invalid_env) do
      #NOTE: This isn't the same msg as other scenarios, don't try to refactor `stop_boot/1` to include the msg...
      stop_boot("""
      Memelex has detected an invalid configuration.
   
      To run the Memex, you need to set up a valid Memex directory in the `config.exs` file. For example, if you wanted the name of the memex to be `JediLuke` (my GitHub name), you would have a config like this:

      config :memelex,
         environment: %{
            name: "JediLuke",
            memex_directory: "~/memex/JediLuke",
            backups_directory: "~/memex/backups/JediLuke"
         }
   
      As we cannot continue, Memelex will now exit. Once you have performed the necessary config changes, simply restart the Memex and try again.
      """)
   end
 
   # def start_new_memex(env) do
   #    Logger.info "No `#{env.name}` Memex environment detected."
   #    Logger.info "Creating new memex directory: #{env.memex_directory}..."
   #    :ok = File.mkdir_p!(env.memex_directory)
   #    # Memelex.Environment.start_link(env)
   # end
 
   def load_existing_memex(env) do
      Logger.info "Loading `#{env.name}` Memex..."
      Memelex.Supervisor.start_link(env)
   end
 
   def stop_boot(msg) do
      Logger.error(msg)

      # Exit in a separate process, so we don't get a warning in console
      # about not having correct return for handle_continue/2
      
      #TODO if we're just running Memelex then fine, die here,
      # but if we're running Flamelex we should just do:

      # Application.put_env(:memelex, :active?, false)

      # and let Flamelex boot as normal (for this mode)

      spawn(fn -> System.stop(1) end)
   end
 
   # defp create_new_memex_environment() do
   #   Logger.debug "creating a new Memex environment..."
 
   #   ##TODO ideally I would like to get the User to input a name
   #   #      here, unfortunately, that was tricker than I would like...
 
   #   new_env_map  = %{"name" => "my_env"}
   #   new_env_file = "./environments/#{new_env_map["name"]}.memex-env"
 
   #   Utils.FileIO.writemap(new_env_file, new_env_map)
   #   Logger.info "Loading `#{new_env_map["name"]}` environment..."
   #   :ok
   # end
end
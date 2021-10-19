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
    probe(env)
    {:noreply, state}
  end

  def probe(%{name: name, memex_directory: dir} = env)
    when is_bitstring(name) and is_bitstring(dir) do
      if File.exists?(dir) do
        load_existing_memex(env)
      else
        # start_new_memex(env)
        stop_boot("""
        The Memex directory defined in `config.exs` does not exist.
    
        The directory #{inspect dir} does not exist. Please create it
        before running the Memex. For example, on Linux:

          mkdir -p #{dir}

        Note that the full path must be declared in the config.

        As we cannot continue, Memelex will now exit. Once you have performed
        the necessary config changes, simply restart the Memex and try again.
        """)
      end
  end

  def probe(_invalid_env) do
    stop_boot("""
    Memelex has detected an invalid configuration.

    To run the Memex, you need to set up a valid Memex directory
    in the `config.exs` file. For example, if you wanted the name
    of the memex to be `JediLuke` (my GitHub name), you would have
    a config like this:

    config :memex,
      environment: %{
        name: "JediLuke",
        memex_directory: "~/memex/JediLuke",
        backups_directory: "~/memex/backups/JediLuke"
      }

    As we cannot continue, Memelex will now exit. Once you have performed
    the necessary config changes, simply restart the Memex and try again.
    """)
  end

  # def start_new_memex(env) do
  #   Logger.info "No `#{env.name}` Memex environment detected."
  #   Logger.info "Creating new memex directory: #{env.memex_directory}..."
  #   :ok = File.mkdir_p!(env.memex_directory)
  #   Memex.EnvironmentSupervisor.start_link(env)
  # end

  def load_existing_memex(env) do
    Logger.info "Detected `#{env.name}` environment..."
    Memex.EnvironmentSupervisor.start_link(env)
  end

  def stop_boot(msg) do
    Logger.error msg
    # Exit in a separate process, so we don't get a warning in console
    # about not having correct return for handle_continue/2
    spawn(fn -> System.stop(1) end)
  end
end
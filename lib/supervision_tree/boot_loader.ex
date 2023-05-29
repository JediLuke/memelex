defmodule Memelex.App.BootLoader do
  use GenServer
  require Logger

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl GenServer
  def init(_args) do
    Logger.info("#{__MODULE__} initializing...")

    # REMINDER: By default, Flamelex boots with the memelex config [active?: false]
    case Application.get_env(:memelex, :active?) do
      false ->
        Logger.warn("Memelex booted into mode: `:inactive` -- not starting the Memex.")
        {:ok, %{}}

      true ->
        {:ok, %{}, {:continue, :check_for_memex_environment}}
    end
  end

  @impl GenServer
  def handle_continue(:check_for_memex_environment, state) do
    case Application.get_env(:memelex, :environment) do
      nil ->
        Logger.warn("booting Memex with no environment configured...")
        # TODO ask to start a new environment here??
        {:noreply, state}

      env = %{name: name} when is_bitstring(name) and name != "" ->
        probe(env)
        {:noreply, state}

      otherwise ->
        Logger.error(
          "Memex environment is not configured correctly. Got environment: #{inspect(otherwise)}"
        )

        raise "Memex environment is not configured correctly"
    end
  end

  # def search_for_environment do
  #    case Application.get_env(:memelex, :environment) do

  # case search_for_environment() do
  #    {:found_memex_env, env} ->
  #       probe(env)
  #       {:noreply, state}
  #    :no_env_found ->
  #       # Logger.error "Unable to detect a Memex environment."
  #       # {:noreply, state}
  #       raise "Unable to detect a Memex environment."
  # end
  #    end
  # end

  def boot_env(env) do
    # this function is mainly used when we boot into an inactive memex mode (like in development) and want to boot into a known memex
    if Application.get_env(:memelex, :active?) do
      raise "cannot boot into a new Memex environment as there is already an active Memex environment."
    else
      # just pick up where the bootloader left off...
      probe(env)
    end
  end

  @forbidden_memex_names ["backups", "test"]

  def probe(%{name: forbidden_name}) when forbidden_name in @forbidden_memex_names do
    stop_boot("""
    You cannot create a Memex environment called `#{forbidden_name}`.

    This environment name is disallowed.

    Pick something else.
    """)
  end

  def probe(%{name: name, memex_directory: dir} = env)
      when is_bitstring(name) and
             is_bitstring(dir) do
    if File.dir?(dir) do
      Memelex.Utils.EnviroTools.load_env(env)
    else
      # start_new_memex(env)
      stop_boot("""
      The Memex directory defined in `config.exs` does not exist.

      The directory #{inspect(dir)} does not exist. Please create it before running the Memelex. For example, on Linux:

      mkdir -p #{dir}

      Note that the full path must be declared in the config.

      As we cannot continue, Memelex will now exit. Once you have performed the necessary config changes, simply restart the Memex and try again.
      """)
    end
  end

  def probe(_invalid_env) do
    # NOTE: This isn't the same msg as other scenarios, don't try to refactor `stop_boot/1` to include the msg...
    stop_boot("""
    Memelex has detected an invalid configuration.

    To run the Memex, you need to set up a valid Memex directory in the `config.exs` file. For example, if you wanted the name of the memex to be `JediLuke` (my GitHub name), you would have a config like this:

    config :memelex,
       environment: %{
          name: "JediLuke",
          memex_directory: "~/memex/JediLuke",
          backups_directory: "~/memex/backups/JediLuke"
       }

    Alternatively, you can place ` `~/.memex` file in your root directory, which is a JSON containing the same details as above.

    The function `Memelex.initialize_environment()` will help you set up a brand new Memex.

    As we cannot continue, Memelex will now exit. Once you have performed the necessary config changes, simply restart the Memex and try again.
    """)
  end

  def stop_boot(msg) do
    Logger.error(msg)

    # TODO if we're just running Memelex then fine, die here,
    # but if we're running Flamelex we should just do:

    # Application.put_env(:memelex, :active?, false)

    # and let Flamelex boot as normal (for this mode)

    # Exit in a separate process, so we don't get a warning in console
    # about not having correct return for handle_continue/2
    spawn(fn -> System.stop(1) end)
  end
end

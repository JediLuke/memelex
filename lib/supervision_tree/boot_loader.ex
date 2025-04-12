defmodule Memelex.App.BootLoader do
  @moduledoc """
  This process checks for a valid Memex environment and boots it if found.

  The process is automatically started as part of the `Memex` app's supervision tree,
  but it could also be called from within an external application (i.e. Flamelex)
  to boot a Memex environment.
  """
  use GenServer
  require Logger

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl GenServer
  def init(_args) do
    Logger.debug("#{__MODULE__} initializing...")

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
    # TODO here - check for dotfiles? or just use the config?
    cond do
      dotfile_found?() ->
        memex_env =
          Memelex.Utils.FileIO.readmap(dotfile())
          |> Memelex.Environment.new()

        probe(memex_env)

        {:noreply, state}

      env_declared_in_elixir_app_config?() ->
        # TODO here we need to load the environment from the config
        # and then boot it
        {:noreply, state}

      true ->
        Logger.warn(
          "booting Memex with no environment configured...\n\nConsider using `Memelex.load_env/1` to load a Memex environment."
        )

        # TODO ask to start/create a new environment here??
        {:noreply, state}
    end
  end

  # def boot_from_dotfile do
  #   dotfile = dotfile_path()
  #   Logger.info("#{__MODULE__} found dotfile at #{dotfile}")

  #   # TODO here we need to load the environment from the dotfile
  #   # and then boot it
  #   {:ok, _} = Memelex.Utils.EnviroTools.load_env_from_dotfile(dotfile)
  # end

  def dotfile_found? do
    File.exists?(dotfile())
  end

  def dotfile do
    # Get the current user's home directory
    home_dir = System.user_home()

    # Construct the path to the .memex file in the home directory
    Path.join(home_dir, ".memex")
  end

  # TODO
  def env_declared_in_elixir_app_config?, do: false

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

  def probe(%{name: memex_name, memex_directory: memex_dir} = env)
      when is_bitstring(memex_name) and
             is_bitstring(memex_dir) do
    if File.dir?(memex_dir) do
      # def load_env(dir) when is_binary(dir) do
      #   load_env(%{dir: dir})
      # end

      # def load_env(%{dir: memex_env_directory}) do
      # directyor = get_last_directory_part(memex_env_directory)

      memex_env =
        Memelex.Environment.new(%{
          name: memex_name,
          memex_directory: memex_dir
        })

      # load_env(memex_env)
      # end

      Memelex.Utils.EnviroTools.load_env(memex_env)
    else
      # start_new_memex(env)
      stop_boot("""
      The Memex directory specified for this Memex environment does not exist.

      The directory #{inspect(memex_dir)} does not exist. Please create it before running the Memelex. For example, on Linux:

      mkdir -p #{memex_dir}

      Note that the full path must be declared in the config.

      As we cannot continue, Memelex will now exit. Once you have performed the necessary config changes, simply restart the Memex and try again.
      """)
    end
  end

  @example_memex_name "JediLuke"
  @root_dir "/home/os_user"
  def probe(_invalid_env) do
    # NOTE: This isn't the same msg as other scenarios, don't try to refactor `stop_boot/1` to include the msg...
    stop_boot("""
    Memelex has detected an invalid configuration.

    To run the Memex, you need to set up a valid Memex directory in the `config.exs` file. For example, if you wanted the name of the memex to be `JediLuke` (my GitHub name), you would have a config like this:

    config :memelex,
       environment: %{
          name: #{@example_memex_name},
          memex_directory: "#{@root_dir}/memex/#{@example_memex_name}",
          backups_directory: "#{@root_dir}/memex/backups/#{@example_memex_name}"
       }

    Alternatively, you can place `#{@root_dir}/.memex` file in your root directory, which is a JSON containing the same details as above.

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

  # if we have /home/user/some/directory/here, return `here`, the last part
  defp get_last_directory_part(directory) do
    directory |> Path.split() |> List.last()
  end
end

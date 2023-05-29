defmodule Memelex.Utils.EnviroTools do
  @moduledoc """
  This module contains functions required for Memex
  """
  require Logger

  def initialize_new_environment do
    Logger.info("creating a new Memex environment...")

    # TODO what if we already detect an environment!?!?

    IO.gets("Please enter a name for your new Memex: ")
    |> String.trim()
    |> build_new_memex()
  end

  def who_am_i do
    case environment_details() do
      nil ->
        IO.puts("No ideA..!?")
        nil

      %{name: env_name} ->
        IO.puts("Memex env name: #{env_name}")
        env_name
    end
  end

  def environment_details do
    Application.get_env(:memelex, :environment)
  end

  def environment_details(memex_name) when is_binary(memex_name) do
    case Registry.lookup(Memelex.EnviroRegistry, memex_name) do
      [{pid, _value}] when is_pid(pid) ->
        case GenServer.call(pid, :get_environment_details, 5000) do
          {:ok, memex_env} ->
            memex_env

          {:error, reason} ->
            raise "Error retrieving environment details: #{reason}"
        end

      [] ->
        Logger.error("No Memex environment detected")
        nil
    end
  end

  def build_new_memex(env_name) when is_bitstring(env_name) do
    IO.puts("building a new Memex env called `#{env_name}`...")

    memex_env_directory = "#{System.user_home!()}/memex/#{env_name}"
    memex_backups_dir = "#{System.user_home!()}/memex/backups/#{env_name}"

    save_in_default_dir? =
      IO.gets("Can we save memex data in the new directory `#{memex_env_directory}`? [y/n]: ")
      |> then(&(String.downcase(String.trim(&1)) == "y"))

    if not save_in_default_dir? do
      raise "Sorry, we actually don't support anything else right now..."
    else
      IO.puts("Creating new memex directory: `#{memex_env_directory}`...")
      :ok = File.mkdir_p!(memex_env_directory)
      :ok = File.mkdir_p!(memex_backups_dir)

      env_module_name = String.to_atom(env_name)
      IO.puts("custom my_modz module is: #{inspect(env_module_name)}")

      memex_env = %{
        name: env_name,
        my_modz: env_module_name,
        memex_directory: memex_env_directory,
        backups_directory: memex_backups_dir
      }

      IO.puts("Writing custom my_modz.ex file...")
      :ok = Memelex.Utils.GenerateMyModz.write_new_my_modz(memex_env)

      IO.puts("Writing new memex env file...")
      {:ok, dotfile} = write_new_memex_dotfile(memex_env)

      IO.puts("""
      Done. The following has been achieved:

      * Create a new directory `#{memex_env_directory}` to save Memex data into.
      * Written various files into this directory, such as:
        - tidbit-db.json  # this is the file where we save TidBits
        - my_modz.ex      # this will actually be called `your_environment.ex`, it is your custom Elixir module loaded at runtime, separately from the Flamelex codep
      * Create a new  file `#{dotfile}` file in the home directory, so that we recognise this environment on future bootups.
      """)

      boot_now? =
        IO.gets("would you like to boot into your new Memex environment now? [y/n]: ")
        |> then(&(String.downcase(String.trim(&1)) == "y"))

      if boot_now? do
        load_env(memex_env)
      end

      Logger.info("Initialization of new Memex envionment complete.")
    end
  end

  def write_new_memex_dotfile(env_map) do
    memex_dotfile = "#{System.user_home!()}/.memex"
    :ok = Memelex.Utils.FileIO.writemap(memex_dotfile, env_map)
    {:ok, memex_dotfile}
  end

  def load_env(dir) when is_binary(dir) do
    load_env(%{dir: dir})
  end

  def load_env(%{dir: memex_env_directory}) do
    name = get_last_directory_part(memex_env_directory)
    load_env(%{name: name, memex_directory: memex_env_directory})
  end

  def load_env(
        %{
          name: env_name,
          memex_directory: memex_env_directory
        } = memex_env
      )
      when is_bitstring(env_name) do
    Logger.info("Loading `#{memex_env[:name] || "unnamed"}` Memex...")

    # update the app config so we have the details of the current memex loaded
    Application.put_env(:memelex, :environment, memex_env)

    # push an event so other parts of the application can react to booting into the new Memex environment
    Memelex.Utils.EventWrapper.event({:loaded_memex, memex_env})

    {:ok, _pid} = Memelex.App.EnvironmentSupervisor.start_env(memex_env)
    :ok
  end

  def get_last_directory_part(directory) do
    directory
    |> Path.split()
    |> List.last()
  end

  def deactivate do
    environment_details() |> deactivate()
  end

  def deactivate(nil) do
    Logger.warn("cannot deactivate Memex, as there was no active environment...")
  end

  def deactivate(%{name: memex_name}) when is_binary(memex_name) do
    Logger.warn("de-activating #{memex_name}...")

    Registry.lookup(Memelex.EnviroRegistry, {Memelex.Environment.TopSupervisor, memex_name})
    |> case do
      [{pid, _value}] when is_pid(pid) ->
        :ok = DynamicSupervisor.stop(pid)

        # reset Application config
        Application.put_env(:memelex, :environment, nil)

        Logger.info("Memex environment shutdown complete.")
        :ok

      [] ->
        raise "failed to shut down the memex, could not find an Environment process named `#{memex_name}`"
    end
  end
end

defmodule Memelex.Utils.EnviroTools do
  @moduledoc """
  This module contains functions required for Memex
  """
  require Logger

  def start_new_memex do
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
    # TODO lol
    Application.get_env(:memelex, :environment)
  end

  # Registry.lookup(Memelex.EnviroRegistry, {Memelex.Environment, "JediLuke"})

  def environment_details(memex_name) when is_binary(memex_name) do
    case Registry.lookup(Memelex.EnviroRegistry, {Memelex.Environment, memex_name}) do
      [{pid, _value}] when is_pid(pid) ->
        case GenServer.call(pid, :get_environment_details, 5000) do
          {:ok, %Memelex.Environment{} = memex_env} ->
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

      memex_env =
        Memelex.Environment.new(%{
          name: env_name,
          my_modz: env_module_name,
          memex_directory: memex_env_directory,
          backups_directory: memex_backups_dir
        })

      IO.puts("Writing custom my_modz.ex file...")
      :ok = Memelex.Utils.GenerateMyModz.write_new_my_modz(memex_env)

      write_memex_dotfile? =
        IO.gets("Would you like to create a memex dotfile in your home directory? [y/n]: ")
        |> then(&(String.downcase(String.trim(&1)) == "y"))

      if write_memex_dotfile? do
        IO.puts("Writing new memex env file...")
        {:ok, dotfile} = write_new_memex_dotfile(memex_env)
      end


      IO.puts("""
      Done. The following has been achieved:

      * Create a new directory `#{memex_env_directory}` to save Memex data into.
      * Written various files into this directory, such as:
        - tidbit-db.json  # this is the file where we save TidBits
        - my_modz.ex      # this will actually be called `your_environment.ex`, it is your custom Elixir module loaded at runtime, separately from the Flamelex code
      * Create a new dotfile in the home directory, so that we recognise this environment on future bootups, if #{write_memex_dotfile?}.
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

  # def load_env(directory) when is_binary(directory) do
  #   # TODO get the name from inside the directory? Do we even really *need* a name for the Memex??
  #   # assume that the name of the directory is the name of the Memex
  #   name =
  #     directory
  #     |> Path.split()
  #     |> List.last()

  #   memex_env =
  #     Memelex.Environment.new(%{
  #       name: name,
  #       memex_directory: directory
  #     })

  #   load_env(memex_env)
  # end

  def load_env(%Memelex.Environment{} = memex_env) do
    Logger.info("Loading Memelex.Environment `#{memex_env.name}`...")

    # update the app config so we have the details of the current memex loaded
    # TODO this should propbably go away eventually... we want to talk to
    # some kind of central environment manager, who knows what the current
    # active environment is, not just stash it in config!
    :ok = Application.put_env(:memelex, :environment, memex_env)

    # push an event so other parts of the application can react to booting into the new Memex environment
    # Memelex.Utils.EventWrapper.event({:starting_mexex, memex_env})
    Memelex.Fluxus.event({:loaded_memex, memex_env})
    # this event firing is a good idea, but it is supposed to be done
    # by the Memelex.Environment process, not here in this Utils module...

    {:ok, _pid} = Memelex.App.EnvironmentSupervisor.start_env(memex_env)
    :ok
  end

  # # TODO figurte out why this isnt coming in as a Memelex.Environment{}
  # def load_env(%{memex_directory: "/home/luke/memex/JediLuke", name: "JediLuke"}) do
  # end

  def deactivate do
    environment_details() |> deactivate()
  end

  def deactivate(nil) do
    Logger.warn("cannot deactivate Memex, as there was no active environment...")
  end

  def deactivate(%{name: memex_name}) when is_binary(memex_name) do
    Logger.warn("de-activating #{memex_name}...")

    Registry.lookup(Memelex.EnviroRegistry, {Memelex.Environment.TreeTopSuprvsr, memex_name})
    |> case do
      [{pid, _value}] when is_pid(pid) ->
        :ok = DynamicSupervisor.stop(pid)

        # reset Application config
        Application.put_env(:memelex, :environment, nil)

        Logger.info("Memex environment shutdown complete.")
        :ok

      [] ->
        Logger.warning(
          "failed to shut down the memex, could not find an Environment process named `#{memex_name}`"
        )

        Application.put_env(:memelex, :environment, nil)
        # {:ok, %{}}
        :ok
    end
  end
end

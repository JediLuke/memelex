defmodule Memelex.Environment do
  use GenServer
  require Logger

  def start_link(%{name: name} = params) when is_binary(name) do
    GenServer.start_link(__MODULE__, params,
      name: {:via, Registry, {Memelex.EnviroRegistry, {__MODULE__, name}}}
    )
  end

  @impl GenServer
  def init(
        %{
          name: memex_environment_name,
          memex_directory: _memex_dir
        } = memex_env
      )
      when is_binary(memex_environment_name) do
    Logger.info("#{__MODULE__} initializing...")
    {:ok, memex_env, {:continue, :load_memex_from_disk}}
  end

  @impl GenServer
  def handle_continue(:load_memex_from_disk, memex_env) do
    # TODO make this more robust by using a case, or by running this in an async task?
    :ok = load_memex_from_disk(memex_env)
    {:noreply, memex_env}
  end

  def handle_call(:who_am_i?, _from, memex_env) do
    {:reply, {:ok, memex_env.name}, memex_env}
  end

  def handle_call(:get_environment_details, _from, memex_env) do
    {:reply, {:ok, memex_env}, memex_env}
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
  def handle_cast(:reload_modz, %{name: memex_name} = memex_env) do
    # TODO reload all custom agents here aswell

    modz_file = my_modz_filepath(memex_env)

    if File.exists?(modz_file) do
      Logger.info("loading my_modz file... #{inspect(modz_file)}")
      task = reload_modz_file(modz_file)
      {:noreply, memex_env |> Map.merge(%{async_task_ref: task.ref})}
    else
      Logger.warn("No Customizations found for this environment...")
      {:noreply, memex_env}
    end
  end

  # The task completed successfully - note all the same-name variable matching in this header
  def handle_info(
        {ref, {:reloaded_modz_file, [env_module | _rest]}},
        %{name: env_name, async_task_ref: ref} = state
      ) do
    Logger.info("Successfully reloaded my_modz!")

    # We don't care about the soon-incoming DOWN message now, so let's demonitor and flush it
    Process.demonitor(ref, [:flush])

    # TODO ensure that env_name as a string, is same as env_module, and probably save env_module here...
    new_state =
      %{state | async_task_ref: nil}
      |> Map.put(:env_module, env_module)

    {:noreply, new_state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{async_task_ref: ref} = state) do
    Logger.error("An asyncronous task failed!")
    {:noreply, %{state | async_task_ref: nil}}
  end

  def load_memex_from_disk(memex_env) do
    with :ok <- build_environment(memex_env),
         {:ok, _wiki_pid} <- Memelex.WikiServer.start_link(memex_env),
         # Memelex.Env.PasswordManager.start_link(memex_env)
         # TODO check for backups directory, look in memex for backups records
         #  :ok <- GenServer.cast(self(), :check_backups),
         :ok <- GenServer.cast(self(), :reload_modz) do
      :ok
    end
  end

  def build_environment(%{memex_directory: dir}) do
    :ok = File.mkdir_p(dir <> "/images")
    :ok = File.mkdir_p(dir <> "/docs")
    :ok = File.mkdir_p(dir <> "/textfiles")
    :ok
  end

  # def new_modz_file(env_name) do
  #   new_my_modz = Memelex.Utils.GenerateMyModz.new(%{name: env_name})
  #   Memelex.Utils.FileIO.write(my_modz_file(), new_my_modz)
  # end

  def reload_modz do
    Memelex.Utils.EnviroTools.environment_details()
    |> reload_modz()
  end

  def reload_modz(%{name: memex_name}) do
    find_memex_pid!(memex_name) |> GenServer.cast(:reload_modz)
  end

  def find_memex_pid(memex_name) when is_binary(memex_name) do
    case Registry.lookup(Memelex.EnviroRegistry, memex_name) do
      [{pid, _value}] when is_pid(pid) ->
        {:ok, pid}

      [] ->
        {:error, "could not find a #{__MODULE__} process with registered name: #{memex_name}"}
    end
  end

  def find_memex_pid!(memex_name) when is_binary(memex_name) do
    case find_memex_pid(memex_name) do
      {:ok, pid} when is_pid(pid) ->
        pid

      {:error, reason} ->
        raise reason
    end
  end

  def my_modz_filepath(%{memex_directory: dir}) when is_binary(dir) do
    dir <> "/my_modz.ex"
  end

  # def handle_cast(:on_boot, memex_env) do
  #    # #TODO check if this function is exported, and only run it if it is
  #    # case Memelex.My.Modz.on_boot(memex_env) do #NOTE: This module is/must be defined in the `my_customizations.ex` file, which is what we're reloading
  #    #    :ok ->
  #    #          #TODO if I had a behaviour/macro, which automatically added
  #    #          # some callbacks to fetch a custom module name, we could do that...
  #    #          # but honestly I think this is probably easier. Though it may
  #    #          # stop us from loading multiple Memex environments simultaneously,
  #    #          # though that doesn't sound desirable anyway
  #    #          memex_env |> Map.merge(%{modz_module: Memelex.My.Modz})
  #    #    error ->
  #    #          Logger.error "Failed to load Customizations, `on_boot` returned: #{inspect error}"
  #    #          memex_env
  #    # end
  #    {:noreply, memex_env}
  # end

  def reload_modz_file(modz_file) when is_binary(modz_file) do
    # reload the modz_file in a Task, so that it doesn't bring down this part of the Sup tree...
    Task.Supervisor.async_nolink(
      Memelex.Environment.TaskSupervisor,
      fn ->
        do_reload_modz_file(modz_file)
      end
    )
  end

  def do_reload_modz_file(modz_file) do
    Logger.info("Loading customizations from #{modz_file}...")

    # if not Code.ensure_loaded?(memex_name) do
    #    Logger.info ""
    #    [^memex_name] = IEx.Helpers.c modz_file
    #  else
    #    IO.puts "MyModule is not loaded"
    #  end

    # TODO check if it exists - if it does, just recompile, else, load
    modz = IEx.Helpers.c(modz_file)

    # {:reloaded, [^modz_module]} = IEx.Helpers.r(modz_module)

    # TODO custom menu
    # custom_menu = Memelex.Environment.Customizations.custom_menu() #NOTE: This module is/must be defined in the `my_customizations.ex` file, which is what we're reloading
    # TODO reloading this should also update all custom menus, maybe we need to broadcast it out, like a :custom_reloadz topic or something
    # TODO try to load & compile this file, handle failure if it doesn't compile...
    # TODO import all these functions automatically

    {:reloaded_modz_file, modz}
  end
end

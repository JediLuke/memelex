defmodule Memelex.AgentHandler do
  use GenServer
  require Logger
  alias Memelex.Lib.Structs.MemexConcepts.V01.Agent

  # don't immediately try to boot all the agents, wait this long first
  @boot_lag :timer.seconds(1)

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def boot_agent(agent) do
    GenServer.call(__MODULE__, {:boot_agent, agent})
  end

  def boot_agents_under_handler() do
    GenServer.call(__MODULE__, :boot_agents)
  end

  def init(initial_state) do
    # TODO trap exits so that if an Gent crashes it's just that agent
    # TODO move this to a real supervisor I guess... a DynamicUpservisor
    Process.flag(:trap_exit, true)
    Process.send_after(self(), :boot_agents, @boot_lag)
    {:ok, initial_state}
  end

  def handle_call(:boot_agents, _from, state) do
    Logger.debug("#{__MODULE__} is booting all agents in the memex...")
    :ok = boot_agents()
    {:reply, :ok, state}
  end

  def handle_call({:boot_agent, %Agent{} = agent}, _from, state) do
    r = do_boot_agent(agent)
    {:reply, r, state}
  end

  def handle_cast({:boot_agent, %Agent{} = agent}, state) do
    do_boot_agent(agent)
    {:noreply, state}
  end

  # TODO this should probably be a dynamic supervisor, not a GenServer...

  def handle_info({:EXIT, _pid, _reason}, state) do
    # Handle the exit, for example, by restarting the agent or logging the exit
    Logger.error("Agent exited.")
    {:noreply, state}
  end

  def handle_info(:boot_agents, state) do
    :ok = boot_agents()
    {:noreply, state}
  end

  def handle_cast({:start_agent, %Agent{} = agent}, state) do
    do_boot_agent(agent)
    {:noreply, state}
  end

  def start_agent(%Memelex.TidBit{data: %Agent{} = agent}) do
    GenServer.cast(__MODULE__, {:start_agent, agent})
  end

  # TODO where do we actually get this?? Maybe from Memex itself??
  def boot_custom_agents?(), do: true

  defp boot_agents do
    # NOTE - this function isn't public because we need to
    # make sure Agent processes are booted under the AgentHandler,
    # and the process which calls this function will be the one
    # which starts all these agents linked to it
    memex_env = Memelex.Environment.get_environment()

    with :ok <- boot_system_agents(),
         :ok <- boot_custom_agents(memex_env) do
      :ok
    end
  end

  defp boot_system_agents do
    # NOTE NO sYSTEM AGENTS FOR NOW...
    :ok
  end

  # look in the Memex for all the agents, and boot them
  defp boot_custom_agents(_memex_env) do
    if boot_custom_agents?() do
      Memelex.My.Agents.all()
      |> Enum.each(fn %Memelex.TidBit{data: %Agent{} = agent} ->
        do_boot_agent(agent)
      end)
    else
      Logger.warn("Not booting custom agents because `boot_custom_agents?()` returned false.")
    end

    :ok
  end

  defp do_boot_agent(%Agent{config: %{"mfa" => {agent_mod, :start_link, [args]}}} = agent) do
    Logger.debug("#{__MODULE__} attempting to boot #{agent.name}...")

    #{:ok, module_file_path} = Memelex.Utils.AgentUtils.write_agent_module_file(memex_env, agent_t)
    #[{_module, _bytecode}] = Code.load_file(module_file_path)

    mmx_dir = Memelex.Utils.EnviroTools.environment_details().memex_directory
    agent_file = Memelex.Utils.AgentUtils.agent_filepath(agent)

    agent_module_file = Path.join(mmx_dir, agent_file)
    [{agent_mod, _bytecode}] = Code.load_file(agent_module_file)

    # # {:ok, _pid} = agent_mod.start_link(args)
    # # {:error, {:already_started, #PID<0.1911.0>}}

    # # TODO figure out how to handle boot failures...
    # agent_mod.start_link(args)

    # {:module, ^agent_mod} = Code.ensure_loaded(agent_mod)
    case Code.ensure_loaded(agent_mod) do
      {:module, ^agent_mod} ->
        Logger.debug("#{__MODULE__} successfully loaded #{agent_mod}.")

        # TODO check that this Agent hasn't already been booted?? Mayube the ELixir process name conflict will prevent this?>?
        case agent_mod.start_link(args) do
          {:ok, _} ->
            Logger.debug("#{__MODULE__} successfully booted #{agent_mod}.")
            {:ok, "#{__MODULE__} successfully booted #{agent_mod}."}

          {:error, {:already_started, _}} ->
            Logger.warn("#{__MODULE__} tried to boot #{agent_mod} but it was already running.")
            {:error, "#{__MODULE__} tried to boot #{agent_mod} but it was already running."}
        end

      {:error, :nofile} ->
        Logger.debug("#{__MODULE__} unable to load #{agent_mod} because it doesn't exist.")
        {:error, :nofile}

      {:error, reason} ->
        Logger.error("#{__MODULE__} unable to load #{agent_mod}. #{inspect(reason)}")
        {:error, reason}
    end
  end

  def stop_agent(%Memelex.TidBit{
        data: %{config: %{"mfa" => {agent_mod, :start_link, _args}}}
      }) do
    case Process.whereis(agent_mod) do
      nil ->
        Logger.warn("Unable to stop agent #{agent_mod} because it's not running.")

      pid ->
        GenServer.stop(pid)
    end
  end

  # def shutdown_agent(%Memelex.TidBit{
  #       data: %{config: %{"mfa" => {agent_mod, :start_link, _args}}}
  #     }) do
  #   case Process.whereis(agent_mod) do
  #     nil ->
  #       Logger.warn("Unable to shutdown agent #{agent_mod} because it's not running.")

  #     pid ->
  #       GenServer.call(pid, :shutdown)
  #   end
  # end
end

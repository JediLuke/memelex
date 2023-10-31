defmodule Memelex.AgentHandler do
  use GenServer
  require Logger
  alias Memelex.Lib.Structs.MemexConcepts.V01.Agent

  # don't immediately try to boot all the agents, wait this long first
  @boot_lag :timer.seconds(5)

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def boot_agent(agent) do
    GenServer.cast(__MODULE__, {:boot_agent, agent})
  end

  def boot_agents_under_handler() do
    GenServer.call(__MODULE__, :boot_agents)
  end

  def init(initial_state) do
    Process.send_after(self(), :boot_agents, @boot_lag)
    {:ok, initial_state}
  end

  def handle_call(:boot_agents, _from, state) do
    Logger.debug("#{__MODULE__} is booting all agents in the memex...")
    :ok = boot_agents()
    {:reply, :ok, state}
  end

  def handle_cast({:boot_agent, %Agent{} = agent}, state) do
    {:ok, _pid} = do_boot_agent(agent)
    {:noreply, state}
  end

  def handle_info(:boot_agents, state) do
    :ok = boot_agents()
    {:noreply, state}
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
  defp boot_custom_agents(memex_env) do
    if boot_custom_agents?() do
      Memelex.My.Agents.all()
      |> Enum.each(fn %Memelex.TidBit{data: %Agent{} = agent} ->
        {:ok, _pid} = do_boot_agent(agent)
      end)
    else
      Logger.warn("Not booting custom agents because `boot_custom_agents?()` returned false.")
    end

    :ok
  end

  defp do_boot_agent(%Agent{config: %{"mfa" => {agent_mod, :start_link, [args]}}} = agent) do
    Logger.info("#{__MODULE__} is booting agent #{agent.name}...")
    {:module, ^agent_mod} = Code.ensure_loaded(agent_mod)
    {:ok, _pid} = agent_mod.start_link(args)
  end

  def shutdown_agent(%Memelex.TidBit{
        data: %{config: %{"mfa" => {agent_mod, :start_link, _args}}}
      }) do
    case Process.whereis(agent_mod) do
      nil ->
        Logger.warn("Unable to shutdown agent #{agent_mod} because it's not running.")

      pid ->
        GenServer.call(pid, :shutdown)
    end
  end
end

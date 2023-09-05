defmodule Memelex.AgentHandler do
  use GenServer
  require Logger

  # 5 minutes in milliseconds
  @time_gap 300_000

  # Client API

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def boot_agents_under_handler() do
    GenServer.call(__MODULE__, :boot_under_handler)
  end

  # Server Callbacks

  def init(initial_state) do
    # Schedule a message to be sent to this process after the time gap
    Process.send_after(self(), :scheduled_message, @time_gap)
    {:ok, initial_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:boot_under_handler, _from, state) do
    Logger.debug("#{__MODULE__} is booting all agents in the memex...")
    :ok = boot_agents()
    {:reply, :ok, state}
  end

  # TODO next, we want to look in the memex, for "agents" and then start them all up

  def handle_info(:scheduled_message, state) do
    IO.puts("#{__MODULE__} Received scheduled message after #{@time_gap} milliseconds.")
    :ok = boot_agents()
    IO.puts("ALL AGENTS BOOTED!")
    # Process.send_after(self(), :scheduled_message, @time_gap)
    {:noreply, state}
  end

  defp boot_agents do
    # NOTE - this function isn't public because we need to
    # make sure Agent processes are booted under the AgentHandler,
    # and the process which calls this function will be the one
    # which starts all these agents linked to it
    memex_env = Memelex.Environment.get_environment()

    Memelex.Agent.all()
    |> Enum.each(fn %Memelex.TidBit{data: agent} ->
      {:ok, _pid} = Memelex.Agent.start_agent(memex_env, agent)
    end)

    :ok
  end
end

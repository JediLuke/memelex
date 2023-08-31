defmodule Memelex.AgentHandler do
  use GenServer

  # 5 minutes in milliseconds
  @time_gap 300_000

  # Client API

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
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

  # TODO next, we want to look in the memex, for "agents" and then start them all up

  def handle_info(:scheduled_message, state) do
    IO.puts("Received scheduled message after #{@time_gap} milliseconds.")
    # You can handle the message here as needed or schedule another one
    # Process.send_after(self(), :scheduled_message, @time_gap)
    {:noreply, state}
  end
end

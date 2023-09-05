# defmodule YesMan do
#   use GenServer

#   # Client API

#   def start_link(_opts) do
#     GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
#   end

#   # GenServer callbacks

#   def init(_state) do
#     # 30,000 milliseconds == 30 seconds
#     schedule_work(30_000)
#     {:ok, %{}}
#   end

#   def handle_info(:work, state) do
#     IO.puts("Hi")
#     schedule_work(30_000)
#     {:noreply, state}
#   end

#   # Helper function to schedule work
#   defp schedule_work(interval) do
#     Process.send_after(self(), :work, interval)
#   end
# end

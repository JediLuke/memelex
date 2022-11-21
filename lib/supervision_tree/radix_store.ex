defmodule Memelex.Fluxus.RadixStore do
  use Agent
  require Logger

  def start_link(_opts) do
    Agent.start_link(fn -> Memelex.Fluxus.Structs.RadixState.new() end, name: __MODULE__)
  end

  # def initialize(viewport: new_viewport) do
  #   Agent.update(__MODULE__, fn old ->
  #     old |> Map.merge(%{gui: old.gui |> Map.put(:viewport, new_viewport)})
  #   end)
  # end


  def get do
    Agent.get(__MODULE__, & &1)
  end

  #TODO this should be a GenServer so we dont copy the state out & manipulate it in another process

  # def put(state, key, value) do
  #   Agent.update(__MODULE__, &Map.put(&1, key, value))
  # end

  def put(new_radix_state) do
    #Logger.debug("!! updating the Radix with: #{inspect(new_radix_state)}")
    # NOTE: Although I did try it, I decided not to go with using the
    #      event bus for updating the GUI due to a state change. The event-
    #      bus serves it's purpose for funneling all action through one
    #      choke-point, and keeps track of them etc, but just pushing
    #      updates to the GUI is simpler when done via a PubSub (no need to acknowledge
    #      events as complete), and easier to implement, since the EventBus
    #      lib we're using receives events in a separate process to the
    #      one where we actually declared the function. We could forward
    #      the state updates on to each ScenicComponent, but then we
    #      start to have problems of how to handle addressing... the
    #      exact problem that PubSub is a perfect solution for.
    Memelex.Utils.PubSub.broadcast(topic: :radix_state_change, msg: {:radix_state_change, new_radix_state})
    Agent.update(__MODULE__, fn _old -> new_radix_state end)
  end

  def put(new_radix_state, :without_broadcast) do
    Agent.update(__MODULE__, fn _old -> new_radix_state end)
  end
end

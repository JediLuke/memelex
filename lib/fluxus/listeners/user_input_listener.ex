defmodule Memelex.Fluxus.UserInputListener do
    @moduledoc """
    This process listens to events on the :memelex topic, and if they're
    actions, makes stuff happen.
    """
    use GenServer
    require Logger
    use ScenicWidgets.ScenicEventsDefinitions
  
    def start_link(_args) do
      GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    end
  
    def init(_args) do
      EventBus.subscribe({__MODULE__, ["memelex"]})
      {:ok, %{}}
    end
  
    def process({:memelex = _topic, _id} = event_shadow) do
        event = EventBus.fetch_event(event_shadow)
        if not user_input?(event) do
            :ignore
        else
            %EventBus.Model.Event{id: _id, topic: :memelex, data: {:input, input}} = event
            radix_state = Memelex.Fluxus.RadixStore.get() #TODO lock the store?
            # case Memelex.Fluxus.UserInputHandler.process(radix_state, input) do
            case process_with_rescue(radix_state, input) do
                :ignore ->
                    #Logger.debug "#{__MODULE__} ignoring... #{inspect(%{radix_state: radix_state, action: action})}"
                    EventBus.mark_as_completed({__MODULE__, event_shadow})
                {:ok, ^radix_state} ->
                    #Logger.debug "#{__MODULE__} ignoring (no state-change)..."
                    EventBus.mark_as_completed({__MODULE__, event_shadow})
                {:ok, new_radix_state} ->
                    #Logger.debug "#{__MODULE__} processed event, state changed..."
                    Memelex.Fluxus.RadixStore.put(new_radix_state)
                    EventBus.mark_as_completed({__MODULE__, event_shadow})
            end
        end
    end


   defp process_with_rescue(radix_state, input) do
      try do
        Memelex.Keymaps.UserInputHandler.process(radix_state, input)
      rescue
         FunctionClauseError ->
            Logger.warn "input: #{inspect input} not handled by `Memelex.Keymaps.UserInputHandler`"
            :ignore
      else
         #NOTE: I don't think we should allow any InputHandler to return a RadixState,
         # since we dont broadcast out updates from inputs, we just fire actions, and these
         # are where the side-effects take place...
         :ok ->
            {:ok, radix_state |> record_input(input)}
         :ignore ->
            :ignore
      end
   end

   defp record_input(radix_state, {:key, {key, @key_pressed, []}} = input) when input in @valid_text_input_characters do
      # Logger.debug "-- Recording INPUT: #{inspect key}"
      #NOTE: We store the latest keystroke at the front of the list, not the back
      radix_state
      |> put_in([:history, :keystrokes], radix_state.history.keystrokes |> List.insert_at(0, input))
   end

   defp record_input(radix_state, input) do
      # Logger.debug "NOT recording: #{inspect input} as input..."
      radix_state
   end

    defp user_input?(%{data: {:input, _input}}), do: true
    defp user_input?(_otherwise), do: false
  
end
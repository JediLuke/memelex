defmodule Memelex.Fluxus do
   @moduledoc """
   Flamelex.Fluxus implements the `flux` architecture pattern, of React.js
   fame, in Elixir/Scenic. This module provides the interface to that
   functionality.

   ### background

   https://css-tricks.com/understanding-how-reducers-are-used-in-redux/

   ### prior art

   https://medium.com/grandcentrix/state-management-with-phoenix-liveview-and-liveex-f53f8f1ec4d7
   """

  
   # called to fire off an action
   def action(a) do
      #Logger.debug "Fluxus handling action `#{inspect a}`..."
      :ok = EventBus.notify(%EventBus.Model.Event{
         id: UUID.uuid4(),
         topic: :memelex,
         data: {:action, a}
      })
   end

end

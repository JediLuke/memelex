defmodule Memelex.Utils.EventWrapper do
  @moduledoc """
  This module encapsulated the Eventing behaviour used for Memelex
  to interact with external systems (e.g. opening an external text-snippet
  with a 3rd party program, or triggering a UI update in Flamelex).
  """
  require Logger

  def event(e) do
    Logger.debug("Memelex firing event: #{inspect(e)}")

    :ok =
      EventBus.notify(%EventBus.Model.Event{
        id: UUID.uuid4(),
        topic: :memelex,
        data: e
      })
  end

  # case to do
  #   %{type: ["external", "textfile"], data: %{"filepath:" => filepath}} ->
  #     Flamelex.API.Buffer.open()
  #   _else ->
  #     :ok
  # end

  # TODO here is a problem, because we want to route the action through
  # Flamelex.Fluxus.action({
  #   Memelex.Fluxus.Reducers.TidbitReducer,
  #   {:open_tidbit, t}
  # })

  # NOTE - it's possible that the above code, while executing, called
  # Wiki.new, which will auto-magically cause it to be rendered in the
  # memex & potentially even the Editor... for this reason we are going to
  # need a clause which handles :open_tidbit getting called on a tidbit which
  # is already open, which shouldn't be such a hack really as we can just
  # explicitely ignore it
  # Flamelex.Fluxus.action({
  #   Memelex.Fluxus.Reducers.TidbitReducer,
  #   {:open_tidbit, t}
  # })
end

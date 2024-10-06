defmodule Memelex.Fluxus do
  @memelex :memelex

  # todo rename dispatch? More consistent with Flux, and it is kind of a good name, it's the action, you dispatch the event
  def event(e) do
    EventBus.notify(%EventBus.Model.Event{
      id: UUID.uuid4(),
      topic: @memelex,
      data: e
    })
  end
end

defmodule Memelex.Fluxus do
  @topic :memelex

  def event(e) do
    EventBus.notify(%EventBus.Model.Event{
      id: UUID.uuid4(),
      topic: @topic,
      data: e
    })
  end
end

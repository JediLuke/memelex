defmodule Memelex.Fluxus do
  @memelex :memelex

  # def event({:tidbit_saved, %Memelex.TidBit{} = _t}) do
  #   # broadcast out to the TidBit channel


  #   # EventBus.notify(%EventBus.Model.Event{
  #   #   id: UUID.uuid4(),
  #   #   topic: @memelex,
  #   #   data: e
  #   # })
  # end

  # todo rename dispatch? More consistent with Flux, and it is kind of a good name, it's the action, you dispatch the event
  def event(e) do
    EventBus.notify(%EventBus.Model.Event{
      id: UUID.uuid4(),
      topic: @memelex,
      data: e
    })
  end
end

defmodule Memelex.EventListener do
  @moduledoc """
  This process listens to events on the :memelex topic, which exists
  inside the Memelex app.
  """
  use GenServer
  require Logger

  @topic :memelex

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_args) do
    EventBus.subscribe({__MODULE__, ["memelex"]})
    {:ok, %{}}
  end

  def process({@topic, _id} = event_shadow) do
    event = EventBus.fetch_event(event_shadow)
    %EventBus.Model.Event{id: _id, topic: @topic, data: memelex_event} = event

    case do_process(memelex_event) do
      r when r in [:ok, :ignore] ->
        EventBus.mark_as_completed({__MODULE__, event_shadow})

      err ->
        raise "#{__MODULE__} failed to process an event: #{inspect(memelex_event)}, error: #{inspect(err)}"
    end
  end

  # we may not want to react to all events, especially ones which may be primarily
  # there to send up to Flamelex when running embedded within that application
  @ignored_events [
    :loaded_memex,
    :open_tidbit,
    :tidbit_saved,
    :reloaded_my_modz,
    :show_todos
  ]

  def do_process(ignored_event)
      when ignored_event in @ignored_events do
    Logger.info("Memelex ignoring an event: #{inspect(ignored_event)}...")
    :ignore
  end

  def do_process({ignored_event, _data}) do
    do_process(ignored_event)
  end

  def do_process({:open_text_snippet, %{data: %{"file_path" => file_path}}}) do
    # raise "here we should open it in sublime or gedit"
    Memelex.Utils.ToolBag.open_gedit(file_path)
  end

  # def do_process(memelex_event) do
  #   Logger.warn("#{__MODULE__} *NOT* handling event: #{inspect(memelex_event)} - ignoring...")
  #   :ignore
  # end
end

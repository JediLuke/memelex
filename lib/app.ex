defmodule Memelex.App do
  @moduledoc false
  use Application

  def start(_type, _args) do
    IO.puts("Starting Memex application...")

    # we have to register the EventBus topic on the fly, because when this app
    # is started by Flamelex using `Application.ensure_all_started/1` the EventBus
    # has _already_ been started (by Flamelex) so the topic won't get registered
    # just by having it inside the Memelex config...
    :ok = EventBus.register_topic(:memelex)

    # Memelex may run as a standalone application, in which case it needs it's own
    # event listening code, or it may run embedded from within Flamelex, in which case
    # Flamelex will listen to Memelex events & handle them (and any interactions with
    # external systems). So if we were started by Flamelex, don't boot the Event listeners.
    started_by_flamelex? = Application.get_env(:memelex, :started_by_flamelex?) || false

    base_children = [
      {Registry, keys: :unique, name: Memelex.EnviroRegistry},
      Memelex.App.EnvironmentSupervisor,
      Memelex.App.BootLoader
    ]

    children =
      if started_by_flamelex? do
        base_children
      else
        base_children ++ [Memelex.EventListener]
      end

    # NOTE: by hiding lots of boilerplate behind `Memelex.App` we
    # use namespacing to our advantage to hide supervision tree
    # modules away a little bit in the CLI...

    opts = [
      name: Memelex.App,
      strategy: :rest_for_one
    ]

    Supervisor.start_link(children, opts)
  end
end

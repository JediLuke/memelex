defmodule Memelex.Application do
  @moduledoc false
  use Application


  def start(_type, _args) do

    IO.puts "Starting Memex application..."

    children = [
      # Memelex.BootCheck,
      {Scenic, [viewport_config()]}
    ]

    opts = [
      name: __MODULE__,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, opts)
  end


  @macbook_pro {1440, 855}
  @window_size_macbook_pro_2 {1680, 1005}
  @window_size_monitor_32inch {2560, 1395}
  # @window_size_terminal_80col {800, 600}   # with size 24 font

  def viewport_config do
    [
      name: :main_viewport,
      size: @macbook_pro,
      default_scene: {Memelex.GUI.RootScene, nil},
      drivers: [
        [
          module: Scenic.Driver.Local,
          window: [title: "Memelex", resizeable: true],
          on_close: :stop_system
        ]
      ]
    ]
  end


end

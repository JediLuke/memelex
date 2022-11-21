defmodule Memelex.GUI.Components.Diary do
   use Scenic.Component
   alias ScenicWidgets.Core.Structs.Frame
   require Logger

   def validate(%{frame: %Frame{} = _f} = data) do
      # Logger.debug "#{__MODULE__} accepted params: #{inspect data}"
      {:ok, data}
   end

   def init(scene, args, opts) do
      Logger.debug("#{__MODULE__} initializing...")
  
      # pubsub_mod = Module.concat(args.app, Utils.PubSub)
      # pubsub_mod.subscribe(topic: :radix_state_change)
  
      init_graph =
      #   render(args)
         Scenic.Graph.build()
         |> Scenic.Primitives.text("Memelex",
            font: :ibm_plex_mono,
            # font: args.font.name,
            # font_size: args.font.size,
            # fill: args.theme.text,
            fill: :white,
            # TODO this is what scenic does https://github.com/boydm/scenic/blob/master/lib/scenic/component/input/text_field.ex#L198
            translate: {100, 100}
      )
      |> Scenic.Primitives.line({{10, 10}, {200, 200}}, stroke: {1, :white})
      
      # init_state =
      #   calc_state(args.radix_state)
        
      init_scene =
        scene
      #   |> assign(app: args.app)
      #   |> assign(font: args.radix_state.editor.font)
      #   |> assign(frame: args.frame)
        |> assign(graph: init_graph)
      #   |> assign(state: init_state)
        |> push_graph(init_graph)
  
      {:ok, init_scene}
    end
end
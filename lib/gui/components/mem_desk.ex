defmodule Memelex.GUI.Components.MemDesk do
   use Scenic.Component
   alias ScenicWidgets.Core.Structs.Frame
   alias ScenicWidgets.Core.Utils.FlexiFrame
   require Logger

   def validate(%{frame: %Frame{} = _f, state: %{story_river: _river}, app: _app} = data) do
      # Logger.debug "#{__MODULE__} accepted params: #{inspect data}"
      {:ok, data}
   end

   def init(scene, args, opts) do
      Logger.debug("#{__MODULE__} initializing...")
  
      # pubsub_mod = Module.concat(args.app, Utils.PubSub)
      # pubsub_mod.subscribe(topic: :radix_state_change)
  
      init_graph = render(args)

      
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

   def render(%{frame: frame, state: memex_state, app: app}) do

      [left_bar|other_frames] = FlexiFrame.columns(frame, 3, :memex)
      [middle_section|right_pane] = other_frames
      right_pane = hd(right_pane)


      Scenic.Graph.build()
      # |> ScenicWidgets.FrameBox.add_to_graph(%{frame: left_bar, fill: :purple})
      # |> ScenicWidgets.FrameBox.add_to_graph(%{frame: middle_section, fill: :yellow})
      |> Memelex.GUI.Components.CollectionsMantel.add_to_graph(%{
         frame: left_bar,
         state: %{}
      })
      |> Memelex.GUI.Components.StoryRiver.add_to_graph(%{
            frame: middle_section,
            state: memex_state.story_river,
            app: app
      }) 
      |> Memelex.GUI.Component.Memex.SideBar.add_to_graph(%{
            frame: right_pane,
            state: memex_state
      })


      # |> ScenicWidgets.FrameBox.add_to_graph(%{frame: right_pane, fill: :red})

      # |> Scenic.Primitives.text("Memelex",
      #    font: :ibm_plex_mono,
      #    # font: args.font.name,
      #    # font_size: args.font.size,
      #    # fill: args.theme.text,
      #    fill: :white,
      #    # TODO this is what scenic does https://github.com/boydm/scenic/blob/master/lib/scenic/component/input/text_field.ex#L198
      #    translate: {100, 100}
      # )


      #         |> Memex.SideBar.add_to_graph(%{
      #                 frame: right_quadrant(args.frame),
      #                 state: args.state.sidebar})


      # |> Scenic.Primitives.line({{10, 10}, {200, 200}}, stroke: {1, :white})
   end
end
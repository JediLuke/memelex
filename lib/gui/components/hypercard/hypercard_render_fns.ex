defmodule Memelex.GUI.Components.HyperCard.Render do
    alias ScenicWidgets.Core.Structs.Frame

    @margin 5

    @header_height 100 # TODO customizable?
    @toolbar_width 150

   def hyper_card(%{state: %{gui: %{mode: :edit}}} = args) do
      Scenic.Graph.build()
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> Scenic.Primitives.rect(args.frame.size, fill: :yellow, stroke: {2, :blue})
         |> render_header(args)
         |> render_editable_body(args |> Map.merge(%{active?: false}))
      end, [
         id: {:hypercard, args.state.uuid},
         translate: args.frame.pin
      ])
   end

   def hyper_card(args) do
      Scenic.Graph.build()
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> Scenic.Primitives.rect(args.frame.size, fill: :antique_white, stroke: {2, :blue})
         |> render_header(args)
         |> render_body(args)
      end, [
         id: {:hypercard, args.state.uuid},
         translate: args.frame.pin
      ])
   end


     # 		# - work on body component displaying how we actually want it to work
# 		# - wraps at correct width
# 		# - renders infinitely long
# 		# - only works for pure text, shows "NOT AVAILABLE" or whatever otherwise (centered ;)





# 	#TODO write a blog post about using matches to distinguish the case vs just for convenience (if for convenience, do it inside the function)


# 		#TODO here we need to pre-calculate the height of the TidBit
# 		# body_height = calc_wrapped_text_height(%{frame: frame, text: data})
# 		# this is a workaround because of flex_grow
# 		{width, {:flex_grow, %{min_height: min_height}}} = frame.size
# 		frame_size = {width, min_height}

# 		|> render_tags_box(%{mode: :edit, tidbit: tidbit, frame: frame})
# 		|> render_text_pad(%{mode: :read_only, tidbit: tidbit, frame: frame})

# 		background_color = :pink
# 		frame = args.frame


# 		#TODO here we need to pre-calculate the height of the TidBit
# 		# this is a workaround because of flex_grow
# 		{width, {:flex_grow, %{min_height: min_height}}} = frame.size
# 		frame_size = {width, min_height}


# 		#TODO here we need to pre-calculate the height of the TidBit
# 		# this is a workaround because of flex_grow
# 		{width, {:flex_grow, %{min_height: min_height}}} = frame.size
# 		frame_size = {width, min_height}

# 		|> render_dateline(tidbit)
# 		|> render_tags_box(%{mode: :read_only, tidbit: tidbit, frame: frame})
# 		|> show_unrenderable_box(%{tidbit: tidbit, frame: frame})


   defp render_header(graph, %{frame: frame, state: %{gui: %{mode: :edit}}} = args) do
      graph
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> Scenic.Primitives.rect({frame.dimens.width-(2*@margin), @header_height}, fill: :blue)
         |> render_editable_title(args)
         |> render_toolbar(args)
      end, [
         id: {:hypercard, args.state.uuid},
         translate: {@margin, @margin}
         ]
      )
   end
  
   defp render_header(graph, %{frame: frame} = args) do
      graph
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> Scenic.Primitives.rect({frame.dimens.width-(2*@margin), @header_height}, fill: :grey)
         |> render_title(args)
         |> render_toolbar(args)
      end, [
         id: {:hypercard, args.state.uuid},
         translate: {@margin, @margin}
         ]
      )
   end

   defp render_editable_title(graph, %{frame: fr, state: %{uuid: tidbit_uuid, gui: %{mode: :edit}} = tidbit} = args) do
      graph
      |> ScenicWidgets.TextPad.add_to_graph(%{
         frame: title_frame(fr),
         state: ScenicWidgets.TextPad.new(%{
            text: tidbit.title,
            font: title_font()
         })
      }, id: {:hypercard_title, tidbit_uuid})
   end

     defp render_title(graph, %{frame: frame, state: tidbit}) do
        # REMINDER: Because we render this from within the group
        # (which is already getting translated, we only need be
        # concerned here with the _relative_ offset from the group.
        # Or in other words, this is all referenced off the top-left
        # corner of the HyperCard, not the top-left corner of the screen.

        font = title_font()
  
        #TODO make title 0.72 * width of Hypercard (minus margins)
        graph
        |> Scenic.Primitives.group(
           fn graph ->
              graph
              |> Scenic.Primitives.rect(title_frame_size(frame), fill: :red)
              |> Scenic.Primitives.text(tidbit.title, font: font.name, font_size: font.size, fill: :black, translate: {5, font.ascent})
           end
              # scissor: {100, 20},
              # translate: 
        )
     end

   defp render_toolbar(graph, %{frame: frame, state: %{uuid: tidbit_uuid, gui: %{mode: :edit}}}) do
      graph
      |> Scenic.Primitives.group(
         fn graph ->
            graph
            |> Scenic.Primitives.rect({@toolbar_width, @header_height/2}, fill: :purple)
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-150, 0}, size: {50, 50}), icon: "ionicons/black_32/trash.png"}, id: {:delete, tidbit_uuid})
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-100, 0}, size: {50, 50}), icon: "ionicons/black_32/backspace.png"}, id: {:discard, tidbit_uuid})
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-50, 0}, size: {50, 50}), icon: "ionicons/black_32/save.png"}, id: {:save, tidbit_uuid})
            # |> Scenic.Primitives.text(title, font: :ibm_plex_mono, font_size: 20)
         end,
            # scissor: {100, 20},
            translate: {frame.dimens.width-(2*@margin)-@toolbar_width, 0}
      )
   end
  
     defp render_toolbar(graph, %{frame: frame, state: %{uuid: tidbit_uuid} = state}) do
        graph
        |> Scenic.Primitives.group(
           fn graph ->
              graph
              |> Scenic.Primitives.rect({@toolbar_width, @header_height/2}, fill: :cyan)
              |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-150, 0}, size: {50, 50}), icon: "ionicons/black_32/chevron-down.png"}, id: {:chevron_down, tidbit_uuid})
              |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-100, 0}, size: {50, 50}), icon: "ionicons/black_32/edit.png"}, id: {:edit, tidbit_uuid})
              |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-50, 0}, size: {50, 50}), icon: "ionicons/black_32/close.png"}, id: {:close, tidbit_uuid})
              # |> Scenic.Primitives.text(title, font: :ibm_plex_mono, font_size: 20)
           end,
              # scissor: {100, 20},
              translate: {frame.dimens.width-(2*@margin)-@toolbar_width, 0}
        )
     end

     defp render_editable_body(graph, %{active?: false} = args) do
      graph
      |> Scenic.Primitives.group(fn graph ->
         graph
         # |> Scenic.Primitives.rect({frame.dimens.width-(2*@margin), frame.dimens.height-(2*@margin)-@header_height}, fill: :purple)
         |> ScenicWidgets.TextPad.add_to_graph(%{
            frame: body_frame(args.frame),
            state: ScenicWidgets.TextPad.new(%{
               text: args.state.title,
               font: body_font()
            })
         }, id: {:hypercard, :body, :text_pad, args.state.uuid})
      end, [
         id: {:hypercard, :body, args.state.uuid},
         translate: {@margin, @margin+@header_height}
         ]
      )
     end
  
     defp render_body(graph, %{frame: frame} = args) do
        graph
        |> Scenic.Primitives.group(fn graph ->
           graph
           |> Scenic.Primitives.rect({frame.dimens.width-(2*@margin), frame.dimens.height-(2*@margin)-@header_height}, fill: :purple)
        end, [
           id: {:hypercard, :body, args.state.uuid},
           translate: {@margin, @margin+@header_height}
           ]
        )
     end
   
   defp title_frame(tidbit_frame) do
      # title_frame_pin = {
      #    tidbit_frame.coords.x+@margin,
      #    tidbit_frame.coords.y+@margin
      # }

      # NOTE - the pin is in reference to the top-left corner of the TidBit
      # We don't need to add any margin because that already gets dont in render_header
      Frame.new(pin: {0, 0}, size: title_frame_size(tidbit_frame))
   end

   defp body_frame(tidbit_frame) do
      Frame.new(
         pin: {0, 0},
         size: {tidbit_frame.dimens.width-(2*@margin), tidbit_frame.dimens.height-(2*@margin)-@header_height}
      )
   end

   defp title_frame_size(tidbit_frame) do
      {tidbit_frame.dimens.width-(2*@margin)-@toolbar_width, 3*@header_height/4}
   end

   defp title_font do
      #TODO dont do this here, pass it in from the config

      #TODO...
      {:ok, ibm_plex_mono_font_metrics} =
         TruetypeMetrics.load("./assets/fonts/IBMPlexMono-Regular.ttf")
     
      #TODO make this more efficient, pass it in same everywhere
      ascent = FontMetrics.ascent(36, ibm_plex_mono_font_metrics)
      
      %{
         name: :ibm_plex_mono,
         size: 36,
         metrics: ibm_plex_mono_font_metrics,
         ascent: ascent
      }
   end

   defp body_font do
      #TODO dont do this here, pass it in from the config

      #TODO...
      {:ok, ibm_plex_mono_font_metrics} =
         TruetypeMetrics.load("./assets/fonts/IBMPlexMono-Regular.ttf")
     
      #TODO make this more efficient, pass it in same everywhere
      ascent = FontMetrics.ascent(36, ibm_plex_mono_font_metrics)
      
      %{
         name: :ibm_plex_mono,
         size: 24,
         metrics: ibm_plex_mono_font_metrics,
         ascent: ascent
      }
   end
end
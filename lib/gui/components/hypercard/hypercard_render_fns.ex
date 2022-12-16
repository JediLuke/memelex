defmodule Memelex.GUI.Components.HyperCard.Render do
	#TODO document this point
	#TODO good idea: render each sub-component as a seperate graph,
    #                calculate their heights, then use Scenic.Graph.add_to
    #                to put them into the `:hypercard_itself` group
    #                -> Unfortunately, this doesn't work because Scenic
    #                doesn't seem to support "merging" 2 graphs, or
    #                if I return a graph (each component), no way to
    #                simply add that to another graph, as a sub-component
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
           # |> render_body(args)
        end, [
           id: {:hypercard, args.state.uuid},
           translate: args.frame.pin
        ]
     )
     end




# 	#TODO write a blog post about using matches to distinguish the case vs just for convenience (if for convenience, do it inside the function)
#     def render_tidbit(graph, %{state: %{
# 			mode: :edit,
# 			activate: :title, data: text} = tidbit} = args)
# 	when is_bitstring(text) do

# 		# - work on body component displaying how we actually want it to work
# 		# - wraps at correct width
# 		# - renders infinitely long
# 		# - only works for pure text, shows "NOT AVAILABLE" or whatever otherwise (centered ;)

# 		background_color = :red
# 		frame = args.frame


# 		#TODO here we need to pre-calculate the height of the TidBit
# 		# body_height = calc_wrapped_text_height(%{frame: frame, text: data})
# 		# this is a workaround because of flex_grow
# 		{width, {:flex_grow, %{min_height: min_height}}} = frame.size
# 		frame_size = {width, min_height}

# 		graph
# 		|> Scenic.Primitives.rect(frame_size, fill: background_color) # background rectangle
# 		|> render_heading(tidbit, frame, mode: :edit)
# 		|> Scenic.Components.button("Save", id: {:save_tidbit_btn, args.id}, translate: {frame.dimensions.width-100, 10})
# 		|> Scenic.Components.button("Discard", id: {:discard_changes_btn, args.id}, translate: {frame.dimensions.width-100, 60})
# 		|> render_tags_box(%{mode: :edit, tidbit: tidbit, frame: frame})
# 		|> render_text_pad(%{mode: :read_only, tidbit: tidbit, frame: frame})
# 	end

# 	def render_tidbit(graph, %{state: %{
# 			mode: :edit,
# 			activate: :body, data: text} = tidbit} = args)
# 	when is_bitstring(text) do

# 		# - work on body component displaying how we actually want it to work
# 		# - wraps at correct width
# 		# - renders infinitely long
# 		# - only works for pure text, shows "NOT AVAILABLE" or whatever otherwise (centered ;)

# 		background_color = :pink
# 		frame = args.frame


# 		#TODO here we need to pre-calculate the height of the TidBit
# 		# body_height = calc_wrapped_text_height(%{frame: frame, text: data})
# 		# this is a workaround because of flex_grow
# 		{width, {:flex_grow, %{min_height: min_height}}} = frame.size
# 		frame_size = {width, min_height}

# 		graph
# 		|> Scenic.Primitives.rect(frame_size, fill: background_color) # background rectangle
# 		|> render_heading(tidbit, frame)
# 		|> Scenic.Components.button("Save", id: {:save_tidbit_btn, args.id}, translate: {frame.dimensions.width-100, 10})
# 		|> Scenic.Components.button("Discard", id: {:discard_changes_btn, args.id}, translate: {frame.dimensions.width-100, 60})
# 		|> render_tags_box(%{mode: :edit, tidbit: tidbit, frame: frame})
# 		|> render_text_pad(%{mode: :edit, tidbit: tidbit, frame: frame})
# 	end



  
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
           ]
        )
     end


     # 	def render_tidbit(graph, %{state: %{
# 			mode: :read_only,
# 			data: text} = tidbit, frame: frame} = args)
# 	when is_bitstring(text) do

# 		#TODO here we need to pre-calculate the height of the TidBit
# 		# this is a workaround because of flex_grow
# 		{width, {:flex_grow, %{min_height: min_height}}} = frame.size
# 		frame_size = {width, min_height}

# 		graph
# 		|> Scenic.Primitives.rect(frame_size, fill: :antique_white) # background rectangle
# 		|> render_heading(tidbit, frame)
# 		|> Scenic.Components.button("Edit", id: {:edit_tidbit_btn, args.id}, translate: {frame.dimensions.width-100, 10})
# 		|> Scenic.Components.button("Close", id: {:close_tidbit_btn, args.id}, translate: {frame.dimensions.width-100, 60})
# 		|> render_dateline(tidbit)
# 		|> render_tags_box(%{mode: :read_only, tidbit: tidbit, frame: frame})
# 		|> render_text_pad(%{mode: :read_only, tidbit: tidbit, frame: frame})
# 	end

# 	# def render_tidbit(graph, %{state: %{edit_mode?: false} = tidbit, frame: frame} = args) do
# 	#NOTE: For now have this case here as a catch-all, but better to really match on a mode
# 	#NOTE: THis case means we failed to match any known case for rendering the body
# 	def render_tidbit(graph, %{state: tidbit, frame: frame} = args) do
# 		Logger.error "Could not successfully render TidBit: #{inspect tidbit}"

# 		#TODO here we need to pre-calculate the height of the TidBit
# 		# this is a workaround because of flex_grow
# 		{width, {:flex_grow, %{min_height: min_height}}} = frame.size
# 		frame_size = {width, min_height}

# 		graph
# 		|> Scenic.Primitives.rect(frame_size, fill: :antique_white) # background rectangle
# 		|> render_heading(tidbit, frame)
# 		|> Scenic.Components.button("Edit", id: {:edit_tidbit_btn, args.id}, translate: {frame.dimensions.width-100, 10})
# 		|> Scenic.Components.button("Close", id: {:close_tidbit_btn, args.id}, translate: {frame.dimensions.width-100, 60})
# 		|> render_dateline(tidbit)
# 		|> render_tags_box(%{mode: :read_only, tidbit: tidbit, frame: frame})
# 		|> show_unrenderable_box(%{tidbit: tidbit, frame: frame})
# 	end


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
  

# 	def render_heading(graph, tidbit, frame, mode: mode) do
# 		graph




# 		|> ScenicWidgets.TextPad.add_to_graph(%{
# 			id: "__heading__" <> tidbit.uuid,
# 			frame: calc_title_frame(frame),
# 			text: tidbit.title,
# 			cursor: Map.get(tidbit, :cursor, 0),
# 			mode: mode,
# 			format_opts: %{
# 				alignment: :left,
# 				wrap_opts: {:wrap, :end_of_line},
# 				show_line_num?: false
# 			},
# 			font: ibm_plex_mono(size: @heading_1)
# 		})
# 		# |> ScenicWidgets.Simple.Heading.add_to_graph(%{
# 		# 	text: tidbit.title,
# 		# 	frame: calc_title_frame(frame),
# 		# 	font: heading_font(),
# 		# 	color: :green,
# 		# 	# text_wrap_opts: :wrap #TODO
# 		# 	background_color: :yellow
# 		# }) #TODO theme: theme?? Does this get automatically passed down??
# 	end

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
            # |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-150, 0}, size: {50, 50}), icon: "ionicons/black_32/chevron-down.png"}, id: :chevron_down)
            # |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-100, 0}, size: {50, 50}), icon: "ionicons/black_32/edit.png"}, id: :edit)
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-50, 0}, size: {50, 50}), icon: "ionicons/black_32/search.png"}, id: {:save, tidbit_uuid})
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
  
     defp render_body(graph, %{frame: frame} = args) do
        graph
        |> Scenic.Primitives.group(fn graph ->
           graph
           |> Scenic.Primitives.rect({frame.dimens.width-(2*@margin), frame.dimens.height-(2*@margin)-@header_height}, fill: :purple)
        end, [
           id: {:hypercard, args.state.uuid},
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
end
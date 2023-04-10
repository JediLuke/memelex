defmodule Memelex.GUI.Components.HyperCard.Render do
   alias ScenicWidgets.Core.Structs.Frame

   @margin 5

   @title_height 50
   @header_height 100 # TODO customizable?
   @toolbar_width 150


   # - work on body component displaying how we actually want it to work
   # wraps at correct width
   # renders infinitely long
   # only works for pure text, shows "NOT AVAILABLE" or whatever otherwise (centered ;)

   #TODO write a blog post about using matches to distinguish the case vs just for convenience (if for convenience, do it inside the function)

   # REMINDER: Because we render this from within the group
   # (which is already getting translated, we only need be
   # concerned here with the _relative_ offset from the group.
   # Or in other words, this is all referenced off the top-left
   # corner of the HyperCard, not the top-left corner of the screen.

   def hyper_card(args) do
      Scenic.Graph.build()
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> render_background(args.frame, args.state)
         |> render_header(args.frame, args.state)
         |> render_body(args.frame, args.state)
      end, [
         id: {:hypercard, args.state.uuid},
         translate: args.frame.pin
      ])
   end

   def render_background(graph, frame, %{gui: %{mode: m}}) when m in [:normal, :edit] do
      color = case m do
         :normal -> :antique_white
         :edit -> :yellow
      end

      graph
      |> Scenic.Primitives.rect(frame.size, fill: color, stroke: {2, :blue})
   end

   def render_header(graph, frame, tidbit) do
      graph
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> render_header_background(frame, tidbit)
         |> render_title(frame, tidbit)
         |> render_toolbar(frame, tidbit)
      end, [
         id: {:hypercard, tidbit.uuid},
         translate: {@margin, @margin}
         ]
      )
   end

   def render_header_background(graph, frame, %{gui: %{mode: :edit}}) do
      graph
      |> Scenic.Primitives.rect({frame.dimens.width-(2*@margin), @header_height}, fill: :blue)
   end

   def render_header_background(graph, frame, %{gui: %{mode: :normal}}) do
      graph
      |> Scenic.Primitives.rect({frame.dimens.width-(2*@margin), @header_height}, fill: :grey)
   end

   def render_title(graph, frame, %{gui: %{mode: :edit, focus: :title}} = tidbit) do
      graph
      |> ScenicWidgets.TextPad.add_to_graph(%{
         frame: title_frame(frame),
         state: ScenicWidgets.TextPad.new(%{
            text: tidbit.title || "",
            font: title_font(),
            cursor: tidbit.gui.cursors.title
         })
      },
         id: {:hypercard, :title, :text_pad, tidbit.uuid}
      )
   end

   def render_title(graph, frame, %{gui: %{mode: :edit, focus: :body}} = tidbit) do
      graph
      |> ScenicWidgets.TextPad.add_to_graph(%{
         frame: title_frame(frame),
         state: ScenicWidgets.TextPad.new(%{
            mode: :read_only,
            text: tidbit.title || "",
            font: title_font()
         })
      },
         id: {:hypercard, :body, :text_pad, tidbit.uuid}
      )
   end

   def render_title(graph, frame, %{gui: %{mode: :normal}} = tidbit) do
      font = title_font()
      title_frame = title_frame(frame)

      graph
      |> Scenic.Primitives.group(
         fn graph ->
            graph
            |> Scenic.Primitives.rect(title_frame.size, fill: :red)
            |> Scenic.Primitives.text(tidbit.title,
                  font: font.name,
                  font_size: font.size,
                  fill: :black,
                  translate: {5, font.ascent}
               )
         end
      )
   end

   def render_toolbar(graph, frame, %{gui: %{mode: :edit}} = tidbit) do
      graph
      |> Scenic.Primitives.group(
         fn graph ->
            graph
            |> Scenic.Primitives.rect({@toolbar_width, @title_height}, fill: :purple)
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-150, 0}, size: {50, 50}), icon: "ionicons/black_32/trash.png"}, id: {:delete, tidbit.uuid})
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-100, 0}, size: {50, 50}), icon: "ionicons/black_32/backspace.png"}, id: {:discard_changes, tidbit.uuid})
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-50, 0}, size: {50, 50}), icon: "ionicons/black_32/save.png"}, id: {:save, tidbit.uuid})
         end,
            translate: {frame.dimens.width-(2*@margin)-@toolbar_width, 0}
      )
   end
  
   def render_toolbar(graph, frame, %{uuid: tidbit_uuid} = tidbit) do
      graph
      |> Scenic.Primitives.group(
         fn graph ->
            graph
            |> Scenic.Primitives.rect({@toolbar_width, @title_height}, fill: :cyan)
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-150, 0}, size: {50, 50}), icon: "ionicons/black_32/chevron-down.png"}, id: {:chevron_down, tidbit.uuid})
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-100, 0}, size: {50, 50}), icon: "ionicons/black_32/edit.png"}, id: {:edit, tidbit.uuid})
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {@toolbar_width-50, 0}, size: {50, 50}), icon: "ionicons/black_32/close.png"}, id: {:close, tidbit.uuid})
         end,
            translate: {frame.dimens.width-(2*@margin)-@toolbar_width, 0}
      )
   end





#     def render_tags_box(graph, %{mode: :read_only, tidbit: tidbit, frame: hypercard_frame}) do
# 		tags_box_frame =
# 			Frame.new(pin: {@opts.margin, 140},
# 					 size: {hypercard_frame.dimensions.width-(2*@opts.margin), 80})

# 		graph
# 		|> Scenic.Primitives.group(
# 			fn graph ->
# 				graph
# 				|> Scenic.Primitives.rect(tags_box_frame.size, fill: :green)
# 				|> Flamelex.GUI.Component.Layout.add_to_graph(%{
# 					frame: tags_box_frame,
# 					components: tags_list(tidbit),
# 					layout: :inline_block
# 				})
# 			end,
# 			translate: tags_box_frame.pin)
# 	end

# 	def render_tags_box(graph, %{mode: :edit, tidbit: tidbit, frame: hypercard_frame}) do
# 		tags_box_frame =
# 			Frame.new(pin: {@opts.margin, 140},
# 					 size: {hypercard_frame.dimensions.width-(2*@opts.margin), 80})

# 		graph
# 		|> Scenic.Primitives.group(
# 			fn graph ->
# 				graph
# 				|> Scenic.Primitives.rect(tags_box_frame.size, fill: :yellow)
# 				|> Flamelex.GUI.Component.Layout.add_to_graph(%{
# 						frame: tags_box_frame,
# 						components: tags_list(tidbit),
# 						layout: :inline_block
# 				})
# 			end,
# 			translate: tags_box_frame.pin)
# 	end


# 	def tags_list(%{tags: tags}) do
# 		tags_list([], tags)
# 	end

# 	def tags_list(acc, []), do: acc

# 	def tags_list(acc, [tag|rest]) when is_bitstring(tag) do
# 		tag_render_fn =
# 			fn(graph, %{frame: frame}) ->
				
# 				{:flex_grow, %{min_width: tag_width}} = frame.dimensions.width #TODO calculate real width from text width

# 				#TODO ok this needs to be it's own component, so it can call back & report it's own size
# 				graph
# 				|> Flamelex.GUI.Component.Layoutable.add_to_graph(%{
# 					render_fn: fn(graph, %{frame: frame}) ->
# 						graph
# 						|> Scenic.Primitives.group( # render a single tag
# 						fn graph ->
# 							graph
# 							|> Scenic.Primitives.rounded_rectangle({tag_width, frame.dimensions.height, 10}, fill: :yellow)
# 							|> Scenic.Primitives.text(tag,
# 								font: :ibm_plex_mono,
# 								translate: {10, 15}, # text draws from bottom-left corner??
# 								font_size: 14, #TODO get this from somewhere better
# 								fill: :black)
# 						end,
# 						translate: frame.pin)
# 					end
# 				})
# 			end

# 		tags_list(acc ++ [tag_render_fn], rest)
# 	end







   # 		#TODO here we need to pre-calculate the height of the TidBit
   # 		# body_height = calc_wrapped_text_height(%{frame: frame, text: data})
   # 		# this is a workaround because of flex_grow
   # 		{width, {:flex_grow, %{min_height: min_height}}} = frame.size
   # 		frame_size = {width, min_height}

   # 		|> render_tags_box(%{mode: :edit, tidbit: tidbit, frame: frame})
   # 		|> render_text_pad(%{mode: :read_only, tidbit: tidbit, frame: frame})

   # 		|> render_dateline(tidbit)
   # 		|> render_tags_box(%{mode: :read_only, tidbit: tidbit, frame: frame})
   # 		|> show_unrenderable_box(%{tidbit: tidbit, frame: frame})

   #TODO render edit / normal modes aswell...
   def render_body(graph, frame, %{type: ["external", "textfile"]} = tidbit) do
      %{"filepath" => fp} = tidbit.data
      
      graph
      #TODO this could be cleaned up, why is it a single component inside a group??
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> render_external_text_file_button(frame, tidbit)
      end, [
         id: {:hypercard, :body, tidbit.uuid},
         translate: {@margin, @margin+@header_height}
         ]
      )
   end

   def render_body(graph, frame, %{gui: %{mode: :edit, focus: :title}} = tidbit) do
      graph
      #TODO this could be cleaned up, why is it a single component inside a group??
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> ScenicWidgets.TextPad.add_to_graph(%{
            frame: body_frame(frame),
            state: ScenicWidgets.TextPad.new(%{
               mode: :read_only,
               text: tidbit.data,
               font: body_font()
            })
         }, id: {:hypercard, :body, :text_pad, tidbit.uuid})
      end, [
         id: {:hypercard, :body, tidbit.uuid},
         translate: {@margin, @margin+@header_height}
         ]
      )
   end

   def render_body(graph, frame, %{gui: %{mode: :edit, focus: :body}} = tidbit) do
      IO.puts "RENDERING EDIT BODY #{inspect tidbit.gui.cursors.body}"
      graph
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> ScenicWidgets.TextPad.add_to_graph(%{
            frame: body_frame(frame),
            state: ScenicWidgets.TextPad.new(%{
               text: tidbit.data,
               font: body_font(),
               cursor: tidbit.gui.cursors.body
            })
         }, id: {:hypercard, :body, :text_pad, tidbit.uuid})
      end, [
         id: {:hypercard, :body, tidbit.uuid},
         translate: {@margin, @margin+@header_height}
         ]
      )
   end
  
   def render_body(graph, frame, %{gui: %{mode: :normal}} = tidbit) do
      graph
      |> Scenic.Primitives.group(fn graph ->
         graph
         |> Scenic.Primitives.rect({frame.dimens.width-(2*@margin), frame.dimens.height-(2*@margin)-@header_height}, fill: :purple)
         |> ScenicWidgets.TextPad.add_to_graph(%{
            frame: body_frame(frame),
            state: ScenicWidgets.TextPad.new(%{
               mode: :read_only,
               text: tidbit.data,
               font: body_font(),
            })
         }, id: {:hypercard, :body, :text_pad, tidbit.uuid})
      end, [
         id: {:hypercard, :body, tidbit.uuid},
         translate: {@margin, @margin+@header_height}
         ]
      )
   end

   def render_external_text_file_button(graph, frame, tidbit) do

      %{type: ["external", "textfile"], data: %{"filepath" => journal_entry_filepath}} = tidbit

      graph
      |> Scenic.Primitives.group(fn graph ->
         graph
         # |> Scenic.Primitives.rect({@header_height, @header_height}, fill: :gold)
         |> Scenic.Components.button("Open external text-file", id: {:open_external_textfile, journal_entry_filepath}, t: {10, 10})
      end, [
         id: {:hypercard, :body, :external_tidbit_btn, tidbit.uuid}
         # translate: {@header_height, @header_height}
         ]
      )
   end
   
   def title_frame(tidbit_frame) do
      # NOTE - the pin is in reference to the top-left corner of the TidBit
      # We don't need to add any margin because that already gets dont in render_header

      #TODO make title 0.72 * width of Hypercard (minus margins)

      Frame.new(
         pin: {0, 0},
         size: {
            tidbit_frame.dimens.width-(2*@margin)-@toolbar_width,
            @title_height
         }
      )
   end

   def body_frame(tidbit_frame) do
      Frame.new(
         pin: {0, 0},
         size: {tidbit_frame.dimens.width-(2*@margin), tidbit_frame.dimens.height-(2*@margin)-@header_height}
      )
   end

   def title_font do
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

   def body_font do
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




























# 	def render_dateline(graph, tidbit) do
# 		graph
# 		|> Scenic.Primitives.text(
# 				tidbit.created |> human_formatted_date(),
# 					font: :ibm_plex_mono,
# 					translate: {@opts.margin, 128},
# 					font_size: 24,
# 					fill: :dark_grey)
# 	end

# 	def render_text_pad(graph, %{mode: mode, tidbit: tidbit, frame: hypercard_frame}) do
# 		graph
# 		|> ScenicWidgets.TextPad.add_to_graph(%{
# 				id: tidbit.uuid,
# 				frame: calc_body_frame(hypercard_frame),
# 				text: tidbit.data,
# 				cursor: Map.get(tidbit, :cursor, 0),
# 				mode: mode,
# 				format_opts: %{
# 					alignment: :left,
# 					wrap_opts: {:wrap, :end_of_line},
# 					show_line_num?: false
# 				},
# 				font: ibm_plex_mono(size: 24) #TODO use a better name like #heading_2 or something
# 		})
# 	end

# 	def calc_body_frame(hypercard_frame) do
# 		#REMINDER: Because we render this from within the group (which is
# 		#		   already getting translated, we only need be concerned
# 		#		   here with the _relative_ offset from the group. Or
# 		#		   in other words, this is all referenced off the top-left
# 		#		   corner of the HyperCard, not the top-left corner
# 		#		   of the screen.
# 		Frame.new(
# 			pin: {@opts.margin, 225},
# 			size: {hypercard_frame.dimensions.width-(2*@opts.margin), 270})
# 	end

# 	def show_unrenderable_box(graph, %{tidbit: tidbit, frame: hypercard_frame}) do
# 		Logger.error "Unable to render TidBit: #{inspect tidbit}"
# 		body_frame = calc_body_frame(hypercard_frame)
# 		graph
# 		|> Scenic.Primitives.rrect(
# 			{body_frame.dimensions.width, body_frame.dimensions.height, 12},
# 			fill: :red,
# 			stroke: {2, :white},
# 			scissor: body_frame.size,
# 			translate: body_frame.pin
# 		  )
# 	end



# 	# defp heading_font do
# 	# 	# This is just the font details for the TidBit/HyperCard heading
# 	# 	Flamelex.Fluxus.RadixStore.get().fonts.ibm_plex_mono
# 	# 	|> Map.merge(%{size: 36})
# 	# end

# 	defp ibm_plex_mono(size: s) do
# 		Flamelex.Fluxus.RadixStore.get().fonts.ibm_plex_mono
# 		|> Map.merge(%{size: s})
# 	end


# 	#     @doc """
# #     Calculates the render height of a bunch of text (after wrapping) for
# #     a given frame (including margins!)
# #     """
# #     def calc_wrapped_text_height(%{frame: frame, text: unwrapped_text}) when is_bitstring(unwrapped_text) do

# #         width = frame.dimensions.width
# #         textbox_width = width-@margin.left-@margin.right

# #         {:ok, metrics} = TruetypeMetrics.load("./assets/fonts/IBMPlexMono-Regular.ttf")
# #         wrapped_text = FontMetrics.wrap(unwrapped_text, textbox_width, @font_size, metrics)

# #         #NOTE: This tells us, how long the body will be - because in Scenic
# #         #      we take the top-left corner as the origin, the bottom of
# #         #      a bounding box is greater than the top. The total height
# #         #      is the bottom minus the top.
# #         {_left, top, _right, bottom} =
# #             Scenic.Graph.build()
# #             |> Scenic.Primitives.text(wrapped_text, font: :ibm_plex_mono, font_size: @font_size)
# #             |> Scenic.Graph.bounds()
        
# #         body_height = (bottom-top)+@margin.top+@margin.bottom

# #         if body_height <= @min_body_height do
# #             @min_body_height
# #         else
# #             body_height
# #         end
# #     end

# #     def calc_wrapped_text_height(_otherwise) do
# #         @min_body_height
# #     end


# end
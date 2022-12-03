defmodule Memelex.GUI.Components.HyperCard do
   use Scenic.Component
   alias Memelex.GUI.Components.HyperCard.Utils
   alias ScenicWidgets.Core.Structs.Frame

   @margin 5

   @header_height 100 # TODO customizable?
   @toolbar_width 140

   def validate(%{frame: _frame, state: %{uuid: _uuid}} = data) do
      {:ok, data}
   end

   def init(scene, args, opts) do
      init_graph = render(args)

      init_scene = scene
      |> assign(graph: init_graph)
      |> push_graph(init_graph)

      {:ok, init_scene}
   end

   def render(args) do
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

   def render_header(graph, %{frame: frame} = args) do
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

   def render_title(graph, %{frame: frame, state: tidbit}) do
      # REMINDER: Because we render this from within the group
      # (which is already getting translated, we only need be
      # concerned here with the _relative_ offset from the group.
      # Or in other words, this is all referenced off the top-left
      # corner of the HyperCard, not the top-left corner of the screen.

      #TODO...
      {:ok, ibm_plex_mono_font_metrics} =
         TruetypeMetrics.load("./assets/fonts/IBMPlexMono-Regular.ttf")

      #TODO make this more efficient, pass it in same everywhere
      ascent = FontMetrics.ascent(36, ibm_plex_mono_font_metrics)

      #TODO make title 0.72 * width of Hypercard (minus margins)
      graph
      |> Scenic.Primitives.group(
         fn graph ->
            graph
            |> Scenic.Primitives.rect({frame.dimens.width-(2*@margin)-@toolbar_width, 3*@header_height/4}, fill: :red)
            |> Scenic.Primitives.text(tidbit.title, font: :ibm_plex_mono, font_size: 36, fill: :black, translate: {5, ascent})
         end
            # scissor: {100, 20},
            # translate: 
      )
   end

   def render_toolbar(graph, %{frame: frame, state: state}) do
      graph
      |> Scenic.Primitives.group(
         fn graph ->
            graph
            |> Scenic.Primitives.rect({@toolbar_width, @header_height/2}, fill: :cyan)
            # |> Scenic.Primitives.text(title, font: :ibm_plex_mono, font_size: 20)
         end,
            # scissor: {100, 20},
            translate: {frame.dimens.width-(2*@margin)-@toolbar_width, 0}
      )
   end

   def render_body(graph, %{frame: frame} = args) do
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

end



# defmodule Flamelex.GUI.Component.Memex.HyperCard do
#     use Scenic.Component
#     require Logger
# 	alias ScenicWidgets.Core.Structs.Frame
# 	alias Flamelex.GUI.Component.Memex.HyperCard.Utils
# 	alias Flamelex.Fluxus.Reducers.Memex, as: MemexReducer

# 	#TODO document this point
# 	#TODO good idea: render each sub-component as a seperate graph,
#     #                calculate their heights, then use Scenic.Graph.add_to
#     #                to put them into the `:hypercard_itself` group
#     #                -> Unfortunately, this doesn't work because Scenic
#     #                doesn't seem to support "merging" 2 graphs, or
#     #                if I return a graph (each component), no way to
#     #                simply add that to another graph, as a sub-component
    
# 	@opts %{
# 		margin: 5
# 	}

# 	#TODO ok so, this could indeed all be rendered away from us -
# 	# all Flamelex components would need frames, ids, some custom_init_logic,
# 	# but they all store the frame & id & state in the scene
# 	def validate(%{
# 			id: _id,
# 			frame: %Frame{} = _f,
# 			state: %{
# 				title: title,
# 			}} = data) when is_bitstring(title) do
# 		Logger.debug("#{__MODULE__} accepted params: #{inspect(data)}")
# 		{:ok, Map.put(data, :state, data.state |> Utils.default_mode(:read_only))}
# 	end
	
# 	def init(scene, args, opts) do
# 		Logger.debug("#{__MODULE__} initializing...")
	
# 		theme = ScenicWidgets.Utils.Theme.get_theme(opts)

# 		init_graph = Utils.render(args |> Map.merge(%{theme: theme}))
	
# 		init_scene = scene
# 			|> assign(graph: init_graph)
# 			|> assign(frame: args.frame)
# 			|> assign(state: args.state)
# 			|> push_graph(init_graph)

# 		Flamelex.Utils.PubSub.subscribe(topic: :radix_state_change)

# 		{:ok, init_scene, {:continue, :publish_bounds}}
# 	end

# 	#REMINDER: Here we call back to the outer-component with out size, since
# 	# 		   HyperCards are flexible in size 
# 	def handle_continue(:publish_bounds, scene) do
#         bounds = Scenic.Graph.bounds(scene.assigns.graph)

# 		#TODO use cast to parent instead
# 		# send_parent_event(scene, {:value_changed, scene.assigns.id, new_text})
# 		Flamelex.GUI.Component.Memex.StoryRiver
# 		|> GenServer.cast({:new_component_bounds, {scene.assigns.state.uuid, bounds}})
        
#         {:noreply, scene, {:continue, :render_next_hyper_card}}
#     end

# 	def handle_continue(:render_next_hyper_card, scene) do
# 		#TODO use cast to parent instead
# 		# send_parent_event(scene, {:value_changed, scene.assigns.id, new_text})
# 		Flamelex.GUI.Component.Memex.StoryRiver |> GenServer.cast(:render_next_component)
# 		{:noreply, scene}
# 	end

# 	def handle_event({:click, {:edit_tidbit_btn, tidbit_uuid}}, _from, scene) do
#         Flamelex.Fluxus.action({MemexReducer, {:edit_tidbit, %{tidbit_uuid: tidbit_uuid}}})
#         {:noreply, scene}
#     end

# 	def handle_event({:click, {:save_tidbit_btn, tidbit_uuid}}, _from, scene) do
#         Flamelex.Fluxus.action({MemexReducer, {:save_tidbit, %{tidbit_uuid: tidbit_uuid}}})
#         {:noreply, scene}
#     end

# 	def handle_event({:click, {:close_tidbit_btn, tidbit_uuid}}, _from, scene) do
#         Flamelex.Fluxus.action({MemexReducer, {:close_tidbit, %{tidbit_uuid: tidbit_uuid}}})
#         {:noreply, scene}
#     end

# 	def handle_event({:click, {:discard_changes_btn, tidbit_uuid}}, _from, scene) do
#         Flamelex.Fluxus.action({MemexReducer, {:discard_changes, %{tidbit_uuid: tidbit_uuid}}})
#         {:noreply, scene}
#     end

# 	#TODO only activate this inside edit mode
# 	def handle_event({:click, {:delete_btn, tidbit_uuid}}, _from, scene) do
#         Flamelex.Fluxus.action({MemexReducer, {:delete, %{tidbit_uuid: tidbit_uuid}}})
#         {:noreply, scene}
#     end

# 	#NOTE: Take note of the matching `tidbit_uuid` variables, these have to be the same for this pattern-match to bind
# 	# #TODO make this be {:body, tidbit_uuid}
# 	# def handle_event({:value_changed, tidbit_uuid, new_text}, _from, %{assigns: %{state: %{uuid: tidbit_uuid, mode: :edit}}} = scene) do
# 	# 	new_tidbit = scene.assigns.state |> Map.merge(%{data: new_text, saved?: false})
# 	# 	Flamelex.Fluxus.action({MemexReducer, {:update_tidbit, new_tidbit}})
#     #     {:noreply, scene}
#     # end


# 	def handle_info({:radix_state_change, _new_radix_state}, scene) do
#         Logger.debug "#{__MODULE__} ignoring a :radix_state_change..."
#         {:noreply, scene}
#     end

# end

defmodule Memelex.GUI.Components.HyperCard do
   use Scenic.Component
   alias Memelex.GUI.Components.HyperCard.{Utils, Render}
   alias Memelex.Reducers.MemexReducer
   



   def validate(%{frame: _frame, state: %{uuid: _uuid}} = data) do
      {:ok, data}
   end

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

   def init(scene, args, opts) do
      init_graph = Render.hyper_card(args)

      init_scene = scene
      |> assign(graph: init_graph)
      |> push_graph(init_graph)

      {:ok, init_scene}
   end

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

# 	def handle_info({:radix_state_change, _new_radix_state}, scene) do
#         Logger.debug "#{__MODULE__} ignoring a :radix_state_change..."
#         {:noreply, scene}
#     end

   def handle_cast({:click, {:close, tidbit_uuid}}, scene) do
      IO.puts "DOORS _ CLOSING"
      #TODO pass it up to the story river (including tidbit info)
      # which will then in turn call the API to close it?? Or just keep doing it here??
      Memelex.Fluxus.action({MemexReducer, {:close_tidbit, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
    end






	def handle_cast({:click, {:edit, tidbit_uuid}}, scene) do
      Memelex.Fluxus.action({MemexReducer, {:edit_tidbit, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
   end

	def handle_cast({:click, {:save, tidbit_uuid}}, scene) do
      # Flamelex.Fluxus.action({MemexReducer, {:save_tidbit, %{tidbit_uuid: tidbit_uuid}}})
      # GenServer.cast(FluxusRadix, )

      # :ok = EventBus.notify(%EventBus.Model.Event{
      #    id: UUID.uuid4(),
      #    topic: :general,
      #    data: {:action, a}
      # })

      Memelex.Fluxus.action({MemexReducer, {:save_tidbit, %{tidbit_uuid: tidbit_uuid}}})

      {:noreply, scene}
    end



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

end

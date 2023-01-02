defmodule Memelex.GUI.Components.HyperCard do
   use Scenic.Component
   alias Memelex.GUI.Components.HyperCard.Render
   alias Memelex.Reducers.RootReducer
   

   def validate(%{frame: _frame, state: %{uuid: _uuid}} = data) do
      {:ok, data}
   end

   def init(scene, args, opts) do
      init_graph = Render.hyper_card(args)

      init_scene = scene
      |> assign(graph: init_graph)
      |> push_graph(init_graph)

      # this should work since we changed the name of the PubSub module...
      # Memelex.Utils.PubSub.subscribe(topic: :radix_state_change)
      pubsub_mod = Module.concat(Flamelex, Utils.PubSub)
      IO.inspect pubsub_mod, label: "PUP PUB - HYPERCARD"
      pubsub_mod.subscribe(topic: :radix_state_change)

      {:ok, init_scene}
   end

   	#TODO document this point
	#TODO good idea: render each sub-component as a seperate graph,
    #                calculate their heights, then use Scenic.Graph.add_to
    #                to put them into the `:hypercard_itself` group
    #                -> Unfortunately, this doesn't work because Scenic
    #                doesn't seem to support "merging" 2 graphs, or
    #                if I return a graph (each component), no way to
    #                simply add that to another graph, as a sub-component

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

   def handle_cast({:click, {:close, tidbit_uuid}}, scene) do
      #TODO pass it up to the story river (including tidbit info)
      # which will then in turn call the API to close it?? Or just keep doing it here??
      Memelex.Fluxus.action({RootReducer, {:close_tidbit, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
   end

	def handle_cast({:click, {:edit, tidbit_uuid}}, scene) do
      Memelex.Fluxus.action({RootReducer, {:edit_tidbit, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
   end

	def handle_cast({:click, {:save, tidbit_uuid}}, scene) do
      Memelex.Fluxus.action({RootReducer, {:save_tidbit, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
   end

   def handle_info({:radix_state_change, new_radix_state}, scene) do
      IO.puts "GOT THE THINGY"
      {:noreply, scene}
   end

# 	def handle_event({:click, {:discard_changes_btn, tidbit_uuid}}, _from, scene) do
#         Flamelex.Fluxus.action({RootReducer, {:discard_changes, %{tidbit_uuid: tidbit_uuid}}})
#         {:noreply, scene}
#     end

# 	#TODO only activate this inside edit mode
# 	def handle_event({:click, {:delete_btn, tidbit_uuid}}, _from, scene) do
#         Flamelex.Fluxus.action({RootReducer, {:delete, %{tidbit_uuid: tidbit_uuid}}})
#         {:noreply, scene}
#     end

# 	#NOTE: Take note of the matching `tidbit_uuid` variables, these have to be the same for this pattern-match to bind
# 	# #TODO make this be {:body, tidbit_uuid}
# 	# def handle_event({:value_changed, tidbit_uuid, new_text}, _from, %{assigns: %{state: %{uuid: tidbit_uuid, mode: :edit}}} = scene) do
# 	# 	new_tidbit = scene.assigns.state |> Map.merge(%{data: new_text, saved?: false})
# 	# 	Flamelex.Fluxus.action({RootReducer, {:update_tidbit, new_tidbit}})
#     #     {:noreply, scene}
#     # end

end

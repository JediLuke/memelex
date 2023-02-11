defmodule Memelex.GUI.Components.HyperCard do
   use Scenic.Component
   alias Memelex.GUI.Components.HyperCard.Render
   #TODO do we want fluxus in these module names??
   alias Memelex.Fluxus.Reducers.RadixReducer
   alias Memelex.Reducers.TidbitReducer
   

   def validate(%{frame: _frame, state: %{uuid: _uuid}} = data) do
      {:ok, data}
   end

   def init(scene, args, opts) do
      init_graph = Render.hyper_card(args)

      init_scene = scene
      |> assign(graph: init_graph)
      |> push_graph(init_graph)

      Memelex.Utils.PubSub.subscribe()

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
      Memelex.Fluxus.action({TidbitReducer, {:close_tidbit, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
   end

	def handle_cast({:click, {:edit, tidbit_uuid}}, scene) do
      Memelex.Fluxus.action({TidbitReducer, {:set_gui_mode, :edit, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
   end

	def handle_cast({:click, {:save, tidbit_uuid}}, scene) do
      Memelex.Fluxus.action({TidbitReducer, {:save_tidbit, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
   end

   def handle_cast({:click, {:discard_changes, tidbit_uuid}}, scene) do
      Memelex.Fluxus.action({TidbitReducer, {:discard_changes, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
   end

   def handle_cast({:click, {:delete, tidbit_uuid}}, scene) do
      Memelex.Fluxus.action({TidbitReducer, {:delete_tidbit, %{tidbit_uuid: tidbit_uuid}}})
      {:noreply, scene}
   end

   def handle_info({:radix_state_change, new_radix_state}, scene) do
      # IO.puts "GOT THE THINGY"
      #TODO would be better if we caught spcific TidBit changes here, rather
      # than re-rendering the entire StoryRiver...
      {:noreply, scene}
   end

end

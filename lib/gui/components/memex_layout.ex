#     def init(init_scene, args, opts) do
#         #Logger.debug "#{__MODULE__} initializing..."
    
#         #NOTE: This component doesn't need to subscribe to RadixState changes

#         #TODO here - use a WindowArrangement of {:columns, [1,2,1]}
#         init_graph = Scenic.Graph.build()
#         #TODO make this a ScenicWidgets.ExpandableNavBar
#         |> ScenicWidgets.FrameBox.add_to_graph(%{frame: left_quadrant(args.frame), color: :alice_blue})
#         |> Memex.StoryRiver.add_to_graph(%{
#                 frame: mid_section(args.frame),
#                 state: args.state.story_river})
#         |> Memex.SideBar.add_to_graph(%{
#                 frame: right_quadrant(args.frame),
#                 state: args.state.sidebar})

#         new_scene = init_scene
#         |> assign(graph: init_graph)
#         |> assign(frame: args.frame)
#         |> assign(state: args.state)
#         |> push_graph(init_graph)

#         # cast_children(scene, :start_caret)
  
#         {:ok, new_scene}
#     end



# end
defmodule Memelex.GUI.Components.StoryRiver do
   use Scenic.Component
   alias ScenicWidgets.Core.Structs.Frame
   require Logger
   #TODO when we need to render a list, need to stash them inside temp state memory until we get "next render" msg from last HyperCard
   # just stash them all in memory & call :render_next_component once, that should do it

   # has input params: Frame, & layout type (axis)
   # then, renders a list of components (another input) with their
   # params (from input), inside this frame-based component which keeps
   # track of how large each rendered, and is able to add/remove them
   # from the screen aswell. We also handle scroll here.

   #NOTE - here's the idea - we have a group that we can add &
   #       subtract to, and a "render list" - we render an item,
   #       it calculates it's own height/length, and the story river
   #       (or whatever) stashes it inside itself as "unrendered" or
   #       something. Then, the first component loads, casts back
   #       "hey, I rendeered, I'm xyz long/high" - this will trigger
   #       the rendering of the next component, and we have all the
   #       data we need!

   @spacing_buffer 20 # the space between TidBits

   def validate(%{
      frame: %Frame{} = _f,
      state: %{
         open_tidbits: _open_tidbits_list,
         scroll_acc: {_x, _y}
      },
      app: _app
   } = data) do
      Logger.debug "#{__MODULE__} accepted params: #{inspect data}"
      {:ok, data}
   end

   # NOTE - it is definitely easier to just get "add_tidbit"
   # here & then update the state that way... if we just accept
   # a state and try to render it, we either need to drop all the old ones,
   # or need to try and compute some kind of diff...

   def init(scene, args, opts) do
      Logger.debug "#{__MODULE__} initializing..."
      
      init_graph = render(args)

      # we have to start out the rendering by moving all
      # open TidBits into the render_queue. Then, we render
      # them one at a time, and then as each one renders it
      # sends this Component, the StoryRiver, an update with it's
      # final height - then, knowing the height of the components
      # it has rendered so far (which are variable in height), the
      # StoryRiver is able to accuractely lay out all the other
      # Hypercards it still has yet to draw
      
      #TODO actually when initializing, we should probably render all the open tidbits...

      init_state =
         args.state
         |> Map.merge(%{scroll_acc: {0, 0}})
         #TODO this might not work with radix_state changes coming in at the same time...
         |> put_in([:open_tidbits], []) # start with no tidbits open, instead we load them into the render queue

         IO.inspect init_state
         #     state = %{
#       # first_render?: true, #NOTE: We can do everything for the "first render" in the init/3 function
#       active_components: [], # we haven't rendered any yet, so none are active
#       render_queue: [] = params.components, # we will go through this list very soon & render them...
#       scroll: {0, 0}
#     }
      
      init_scene = scene
      |> assign(graph: init_graph)
      |> assign(frame: args.frame)
      |> assign(state: init_state)
      #TODO we should render the open tidbits in the init state
      |> assign(render_queue: args.state.open_tidbits) # used to buffer the rendering of flexible components (because they're flexible, so we can't render/position the next one until we know how tall the previous one is)
      |> push_graph(init_graph)
      
      pubsub_mod = Module.concat(args.app, Utils.PubSub)
      pubsub_mod.subscribe(topic: :radix_state_change)

      request_input(init_scene, [:cursor_scroll])

      GenServer.cast(self(), :render_next_component) # kick-start the rendering here, it will take first item in the queue & render it

      {:ok, init_scene}
   end

   def handle_input(
      {:cursor_scroll, {{_x_scroll, y_scroll} = delta_scroll, coords}},
      _context,
      scene
   ) do
         
      #TODO handle all this via a Reducer?? Or just keep it in the component??
      # Flamelex.Fluxus.action({Flamelex.Fluxus.Reducers.Memex, {:scroll, delta_scroll, __MODULE__}})
      
      fast_scroll = {0, 3*y_scroll}
      #TODO cap scroll
      # new_cumulative_scroll =
      #     cap_position(scene, Scenic.Math.Vector2.add(scene.assigns.state.scroll, fast_scroll))
      new_cumulative_scroll =
          Scenic.Math.Vector2.add(scene.assigns.state.scroll_acc, fast_scroll)

      new_graph =
         scene.assigns.graph
         |> Scenic.Graph.modify(:river_pane, &Scenic.Primitives.update_opts(&1, translate: new_cumulative_scroll))

      new_state =
         scene.assigns.state
         |> put_in([:scroll_acc], new_cumulative_scroll)

      new_scene =
         scene
         |> assign(graph: new_graph)
         |> assign(state: new_state)
         |> push_graph(new_graph)

      {:noreply, new_scene}
   end

   def handle_cast(:render_next_component, %{assigns: %{render_queue: []}} = scene) do
      Logger.debug "#{__MODULE__} ignoring a request to render a component, there's nothing to render"
      {:noreply, scene}
   end

   def handle_cast(:render_next_component, %{assigns: %{render_queue: [tidbit|rest]}} = scene) do
      Logger.debug "#{__MODULE__} attempting to render an additional component..."

      #NOTE - pick up here tomorrow,
      # -  basically add the new Hypercard to the graph
      # - push a new graph
      # - remember to take this component out of the render render_queu
      # - next hypercard will kick off next render


      # margin_buf = 2*@spacing_buffer # this is how much margin we render around each HyperCard

      # frame = scene.assigns.frame
      # state = scene.assigns.state
      # new_state = %{state | render_queue: rest}

      # acc_height = calc_acc_height(scene) #TODO loop through active components, calc height, including all spaced offsets!

      # #NOTE - margin ought to be managed by the component itself - dont
      # #       adjust the frame & pass it in, pass in margin as a prop

      # #TODO get current scroll for the river_pane, so we can use it again
      # #     as an option when we add the new HyperCard to the graph - I feel
      # #     like Scenic should have respected my initial options, but anyway...
   




      new_graph = scene.assigns.graph
      |> Scenic.Graph.add_to(:river_pane, fn graph ->
         graph
         # |> ScenicWidgets.FrameBox.add_to_graph(%{frame: Frame.new(%{pin: {400, 400}, size: {400, 400}}), fill: :blue})
         # |> ScenicWidgets.FrameBox.add_to_graph(%{frame: calc_hypercard_frame(scene), fill: :blue})
         |> Memelex.GUI.Components.HyperCard.add_to_graph(%{
                  # id: tidbit.uuid,
                  frame: calc_hypercard_frame(scene),
                  # frame: Frame.new(%{pin: {400, 400}, size: {400, 400}}),
                  # state: tidbit
                  state: %{uuid: "123"}
               })
         end)

      



      # #NOTE this is supposed to get the existing scroll but we need to cann it for now
      # # [%{transforms: %{translate: scroll_coords}}] = Scenic.Graph.get(scene.assigns.graph, :river_pane)

      # #NOTE this seems to have basically no effect on counter-acting the scroll reset when we open a new tidbit problem...
      # # |> Scenic.Graph.modify(:river_pane, &Scenic.Primitives.update_opts(&1, translate: scroll_coords))






      new_state = scene.assigns.state
      |> put_in([:open_tidbits], scene.assigns.state.open_tidbits ++ [tidbit])
      |> IO.inspect(label: "NEW STATE AFTER ADDING TIDBIT")

      new_scene = scene
      |> assign(graph: new_graph)
      |> assign(state: new_state)
      |> assign(render_queue: rest)
      |> push_graph(new_graph)

      GenServer.cast(self(), :render_next_component) # keep rendering all the components...

      {:noreply, new_scene}
   end
 


#   def handle_cast(:render_next_component, scene = %{assigns: %{state: %{
#                     #  active_components: [],
#                      render_queue: [c|rest]}}}) do
#     Logger.debug "Attempting to render an additional component in the LayoutList..."
#     # Logger.warn "IN THE RENDER LIST YES"

#     margin_buf = 2*@spacing_buffer # this is how much margin we render around each HyperCard
#     {HyperCard, tidbit, opts} = c #TODO lol

#     frame = scene.assigns.frame
#     state = scene.assigns.state
#     new_state = %{state | render_queue: rest}

#     acc_height = calc_acc_height(scene) #TODO loop through active components, calc height, including all spaced offsets!

#     #NOTE - margin ought to be managed by the component itself - dont
#     #       adjust the frame & pass it in, pass in margin as a prop

#     #TODO get current scroll for the river_pane, so we can use it again
#     #     as an option when we add the new HyperCard to the graph - I feel
#     #     like Scenic should have respected my initial options, but anyway...

#     #NOTE this is supposed to get the existing scroll but we need to cann it for now
#     # [%{transforms: %{translate: scroll_coords}}] = Scenic.Graph.get(scene.assigns.graph, :river_pane)

#     new_graph = scene.assigns.graph
#     |> Scenic.Graph.add_to(:river_pane, fn graph ->
#           args = %{
#             tidbit: tidbit,
#             frame: Frame.new(pin: {frame.top_left.x, frame.top_left.y+acc_height}, size: {frame.dimensions.width-(2*margin_buf), :flex})
#             # top_left: {frame.top_left.x+margin_buf, frame.top_left.y+margin_buf+acc_height},
#             # width: frame.dimensions.width-(2*margin_buf) # got to take off the margun_buf from each side...
#           }
#           # Kernel.apply(HyperCard, :add_to_graph, [graph, args, [translate: scroll_coords]]) #TODO I dont think this actually worked
#           Kernel.apply(HyperCard, :add_to_graph, [graph, args, opts]) #TODO this always resets us back moving the story river to default! Very annoying!!
#           # |> HyperCard.add_to_graph(%{
#           #     top_left: {},
#           #     width: {},
#           #     length: :flex,
#           #     # frame:  Frame.new(top_left: {frame.top_left.x+bm, existing_graph_height+bm}, dimensions: {frame.dimensions.width-(2*bm), 700}),
#           #     # frame:  Frame.new(top_left: {bottom+15, left}, dimensions: {400, 400}),
#           #     # frame: hypercard_frame(frame), # calculate hypercard based of story_river
#           #     tidbit: tidbit })
#     end)
#     #NOTE this seems to have basically no effect on counter-acting the scroll reset when we open a new tidbit problem...
#     # |> Scenic.Graph.modify(:river_pane, &Scenic.Primitives.update_opts(&1, translate: scroll_coords))

#     # then, riht at the end, call itself again until there's no render queue components (!?!?)
#     # GenServer.cast(self(), :render_next_component)

#     new_scene = scene
#     |> assign(graph: new_graph)
#     |> assign(state: new_state)
#     |> push_graph(new_graph)

#     {:noreply, new_scene}
#   end

 
   # def handle_info({:radix_state_change, %{memex: %{open_tidbits: new_open_tidbits} = new_memex_state}}, %{assigns: %{state: %{open_tidbits: currently_open_tidbits}}} = scene)
   def handle_info({:radix_state_change, %{memex: %{story_river: %{open_tidbits: new_open_tidbits} = new_memex_state} }}, %{assigns: %{state: %{open_tidbits: currently_open_tidbits}}} = scene)
      when new_open_tidbits != currently_open_tidbits do
         # IO.puts "GOT THE MXG #{inspect new_open_tidbits}"

         # new_tidbits_to_render = scene.assigns.state.open_tidbits 

         #TODO add an optimization here, we dont need to destroy all the open tidbits & add *all* of them to the render buffer,
         # most of the time we're just appending a single ne TidBit to the bottom...
         new_scene = scene
         |> assign(state: new_memex_state |> put_in([:open_tidbits], [])) # reset open tidbits to zero, since we need to re-render them all...
         |> assign(render_queue: new_open_tidbits)
         # |> push_graph(init_graph)

         GenServer.cast(self(), :render_next_component)

         {:noreply, new_scene}
   end

   def render(%{frame: frame, state: %{scroll_acc: scroll_acc} = _state}) do
      # This way the graph has a Group with the right name already, so
      # we can just use Scenic.Graph.add to add new HyperCards

      Scenic.Graph.build()
      |> Scenic.Primitives.group(fn graph ->
            graph
            |> ScenicWidgets.FrameBox.add_to_graph(%{frame: frame, fill: :pink})
            #NOTE- make the container group, give it translation etc, just don't add any components yet
            |> Scenic.Primitives.group(fn graph ->
                  graph
               end, [
                  #NOTE: We will scroll this pane around later on, and need to
                  #      add new TidBits to it with Modify
                  id: :river_pane, # Scenic required we register groups/components with a name
                  translate: scroll_acc
            ])
         end, [
            id: __MODULE__
         ]
      )
   end

   def calc_hypercard_frame(%{assigns: %{
      frame: %Frame{coords: %{x: x, y: y}, dimens: %{width: w, height: h}},
      state: %{
          open_tidbits: open_tidbits_list
   }}}) do
      #TODO really calculate height
      open_tidbits_offset = 500*Enum.count(open_tidbits_list)
      extra_vertial_space = @spacing_buffer*Enum.count(open_tidbits_list)
      Frame.new(
          pin: {x+@spacing_buffer, y+@spacing_buffer+open_tidbits_offset+extra_vertial_space},
         #  size: {w-(2*@spacing_buffer), {:flex_grow, %{min_height: 500}}})
          size: {w-(2*@spacing_buffer), 500}) # TODO
   end

   # # <3 @vacarsu
   # def cap_position(%{assigns: %{frame: frame}} = scene, coord) do
   #    # NOTE: We must keep track of components, because one could
   #    #      get yanked out the middle.
   #    height = calc_acc_height(scene)
   #    # height = scene.assigns.state.scroll.acc_length
   #    if height > frame.dimensions.height do
   #       coord
   #       |> calc_floor({0, -height + frame.dimensions.height / 2})
   #       |> calc_ceil({0, 0})
   #    else
   #       coord
   #       |> calc_floor(@min_position_cap)
   #       |> calc_ceil(@min_position_cap)
   #    end
   # end

   # defp calc_floor({x, y}, {min_x, min_y}), do: {max(x, min_x), max(y, min_y)}

   # defp calc_ceil({x, y}, {max_x, max_y}), do: {min(x, max_x), min(y, max_y)}
               

   # def calc_acc_height(components) when is_list(components) do
   #    do_calc_acc_height(0, components)
   # end

   # def calc_acc_height(%{assigns: %{state: %{open_tidbits: open_tidbits}}}) do
   #     do_calc_acc_height(0, open_tidbits)
   # end

   # def do_calc_acc_height(acc, []), do: acc

   # def do_calc_acc_height(acc, [{_id, bounds} = c | rest]) do
   #    # top is less than bottom, because the axis starts in top-left corner
   #    {_left, top, _right, bottom} = bounds
   #    component_height = bottom - top

   #    new_acc = acc + component_height + @spacing_buffer
   #    do_calc_acc_height(new_acc, rest)
   # end




#   defp floor({x, y}, {min_x, min_y}), do: {max(x, min_x), max(y, min_y)}

#   defp ceil({x, y}, {max_x, max_y}), do: {min(x, max_x), min(y, max_y)}



end






#     def handle_cast(
#         {:new_component_bounds, {id, bounds} = new_component_bounds},
#         %{assigns: %{state: state}} = scene
#     ) do
#         # this callback is received when a component boots successfully -
#         # it register itself to this component (parent-child relationship,
#         # which ought to be able to handle props aswell!) including it's
#         # own size (since I want TidBits to grow organizally based on their
#         # size, and only wrap/clip in the most extreme circumstancses and/or
#         # boundary conditions)

#         # NOTE: This callback `:new_component_bounds` is only useful
#         #      for keeping track of all the scrollable components. If
#         #      you need something else to happen when a sub-component
#         #      finished rendering (like say, rendering the next item,
#         #      in a list layout if these items were dynamically large)
#         #      then you will need to make your Components send _additional_
#         #      messages to the parent component, triggering whatever
#         #      other event it is you want to trigger on completion of
#         #      the sub-component rendering. This callback does not assume
#         #      responsibility for forwarding messages or any other messiness.

#         new_state = state
#         |> put_in([:scroll, :components], state.scroll.components ++ [new_component_bounds])

#         new_scene = scene
#         |> assign(state: new_state)

#         {:noreply, new_scene}
#     end

#     def handle_info({:radix_state_change, %{memex: %{story_river: new_story_river_state}}}, %{assigns: %{state: current_state}} = scene)
#         when new_story_river_state != current_state do
#             Logger.debug "#{__MODULE__} updating StoryRiver..."

#             new_graph = render_new_story_river(scene.assigns.state.scroll.accumulator)
#             new_state = new_story_river_state |> put_in([:open_tidbits], []) # start with no tidbits open, instead we load them into the render queue

#             new_scene = scene
#             |> assign(graph: new_graph)
#             |> assign(render_queue: new_story_river_state.open_tidbits)
#             |> assign(state: new_state)
#             |> push_graph(new_graph)

#             GenServer.cast(self(), :render_next_component) # kick-start the rendering here, it will take first item in the queue & render it
    
#             {:noreply, new_scene}
#     end

#     #NOTE: If `story_river_state` binds on both variables here, then they are the same, no state-change occured and we can ignore this update
#     def handle_info({:radix_state_change, %{memex: %{story_river: story_river_state}}}, %{assigns: %{state: story_river_state}} = scene) do
#         {:noreply, scene}
#     end



    



#     # def hypercard_frame(%Frame{top_left: %{x: x, y: y}, dimensions: %{width: w, height: h}}) do
#     #     bm = _buffer_margin = 50 # px
#     #     Frame.new(top_left: {x+bm, y+bm}, dimensions: {w-(2*bm), {:flex_grow, %{min_height: 500}}})
#     # end

#     # def second_hypercard_frame(%Frame{top_left: %{x: x, y: y}, dimensions: %{width: w, height: h}}) do
#     #     bm = _buffer_margin = 50 # px
#     #     Frame.new(top_left: {x+bm+20, y+bm+600}, dimensions: {w-(2*bm), {:flex_grow, %{min_height: 500}}})
#     # end

#     # def render_tidbits(graph, %{state: %{open_tidbits: []}} = _story_river_state) do
#     #     graph |> Scenic.Graph.delete(__MODULE__)
#     # end

#     # def render_tidbits(graph, %{state: %{open_tidbits: [%Memelex.TidBit{} = tidbit], scroll: scroll}, frame: frame}) do
#     #     new_graph = graph
#     #     |> Scenic.Graph.delete(__MODULE__)
#     #     |> Scenic.Primitives.group(fn graph ->
#     #             graph
#     #             |> Flamelex.GUI.Component.Memex.HyperCard.add_to_graph(%{
#     #                     id: tidbit.uuid,
#     #                     frame: hypercard_frame(frame),
#     #                     state: tidbit
#     #             })
#     #         end, [
#     #             id: __MODULE__,
#     #             translate: scroll.accumulator
#     #         ])
#     # end


# end
























# defmodule Flamelex.GUI.Component.LayoutList do #TODO this will be LinearLayout
#   use Scenic.Component
#   use Flamelex.ProjectAliases
#   require Logger
#   alias Flamelex.GUI.Component.Memex.HyperCard

#   # has input params: Frame, & layout type (axis)
#   # then, renders a list of components (another input) with their
#   # params (from input), inside this frame-based component which keeps
#   # track of how large each rendered, and is able to add/remove them
#   # from the screen aswell. We also handle scroll here.

#   #NOTE - here's the idea - we have a group that we can add &
#   #       subtract to, and a "render list" - we render an item,
#   #       it calculates it's own height/length, and the story river
#   #       (or whatever) stashes it inside itself as "unrendered" or
#   #       something. Then, the first component loads, casts back
#   #       "hey, I rendeered, I'm xyz long/high" - this will trigger
#   #       the rendering of the next component, and we have all the
#   #       data we need!


#   # def render(list of components)
#   # def add / remove

#   @spacing_buffer 25 # how much gap to put between each item in the layout
#   @min_position_cap {0, 0}


#   def validate(%{
#         id: _id,
#         frame: %Frame{} = _f,
#         components: compnts,
#         layout: l, #NOTE: Eventually, we want to have this available as "offset" aswell, for e.g. ManuBars - and plz blog this out one day!
#         scroll: true,
#       } = data) when l in [:flex_grow] and is_list(compnts) do

#     # Enum.each(compnts, fn %{module: mod, params: p, opts: o} = p ->
#     #   Logger.debug "valid component: #{inspect p}"
#     # end)

#     Logger.debug "#{__MODULE__} accepted params: #{inspect data}"
#     {:ok, data}
#   end

#   def validate(_data) do
#       {:error, "This component must be passed a %Frame{}"}
#   end

#   def init(scene, params, opts) do
#     Logger.debug "#{__MODULE__} initializing..."



#     Process.register(self(), __MODULE__) #TODO this is something that the old use Component system had - inbuilt process registration

#     #NOTE- make the container group, give it translation etc, just don't add any components yet
#     new_graph =
#       Scenic.Graph.build()
#       |> Scenic.Primitives.group(fn graph ->
#            graph
#          end, [
#             #NOTE: We will scroll this pane around later on, and need to
#             #      add new TidBits to it with Modify
#             id: :river_pane, # Scenic required we register groups/components with a name
#             translate: state.scroll
#          ])

#     new_scene = scene
#     |> assign(state: state)
#     |> assign(frame: params.frame)
#     |> assign(graph: new_graph)
#     |> push_graph(new_graph)

#     GenServer.cast(self(), :render_next_component) # trigger rendering of our (potential) backlog of components to render!
#     # remember, they need to render "one at a time (yuck) - (or do they??) to get their positions"



#       # def handle_cast({:add_tidbit, tidbit}, %{assigns: %{open_tidbits: ot}} = scene) when is_list(ot) do
#     #     IO.puts "YES ADD TIDBIT"

#     #     #TODO hack
#     #     # [{_id, {left, bottom, right, top} = bounds}] = ot
#     #     [{_id, {left, top, right, bottom} = bounds}] = ot

#     #     new_graph =
#     #     scene.assigns.graph
#     #     # |> Scenic.Graph.modify(:river_pane, fn group ->
#     #     #         IO.inspect group, label: "FETCHED RIVER PANE"
#     #     # end)
#     #     |> Scenic.Graph.add_to(:river_pane, fn graph ->
#     #             IO.inspect graph, label: "FETCHED RIVER PANE - inside ADD TO"

#     #             graph
#     #             |> HyperCard.add_to_graph(%{
#     #                 # frame:  Frame.new(top_left: {frame.top_left.x+bm, existing_graph_height+bm}, dimensions: {frame.dimensions.width-(2*bm), 700}),
#     #                 frame:  Frame.new(top_left: {bottom+15, left}, dimensions: {400, 400}),
#     #                 # frame: hypercard_frame(frame), # calculate hypercard based of story_river
#     #                 tidbit: tidbit })

#     #     end)

#     #     # raise "this needs to be converted over to the new system"
#     #     # frame = scene.assigns.frame

#     #     # new_tidbit_list = scene.assigns.open_tidbits ++ [tidbit]
#     #     # # new_graph = scene.assigns.graph
#     #     # # |> Scenic.Primitives.rect({frame.dimensions.width, frame.dimensions.height},
#     #     # # # id: :story_river,
#     #     # # fill: :blue,
#     #     # # translate: {
#     #     # #     frame.top_left.x,
#     #     # #     frame.top_left.y+600 })

#     #     # # new_graph = scene.assigns.graph
#     #     # # |> HyperCard.add_to_graph(%{
#     #     # #         frame: hypercard_frame(frame), # calculate hypercard based of story_river
#     #     # #         tidbit: tidbit },
#     #     # #         id: :hypercard,
#     #     # #         t: scene.assigns.scroll)

#     #     # #TODO modify :river_pane - HERE

#     #     # new_graph = scene.assigns.graph
#     #     # |> Scenic.Graph.delete(:river_pane)
#     #     # |> common_render(scene.assigns.frame, new_tidbit_list, scene.assigns.scroll)
#     #     # # |> Scenic.Graph.modify(:river_pane, fn group ->
#     #     # #     graph
#     #     # #     |> HyperCard.add_to_graph(%{
#     #     # #             frame: second_hypercard_frame(frame), # calculate hypercard based of story_river
#     #     # #             tidbit: tidbit })
#     #     # #             # id: :hypercard,
#     #     # #             # t: scroll)

#     #     # # end)
#     #     # #     |> Scenic.Primitives.group(fn graph ->
#     #     # #     graph
#     #     # #     |> HyperCard.add_to_graph(%{
#     #     # #             frame: hypercard_frame(frame), # calculate hypercard based of story_river
#     #     # #             tidbit: t })
#     #     # #             # id: :hypercard,
#     #     # #             # t: scroll)
#     #     # # end, [
#     #     # #     #NOTE: We will scroll this pane around later on, and need to
#     #     # #     #      add new TidBits to it with Modify
#     #     # #     id: :river_pane, # Scenic required we register groups/components with a name
#     #     # #     translate: scroll
#     #     # # ])

#     #     # # &text(&1, "Updated Text 3") )

#     #     new_scene = scene
#     #     |> assign(graph: new_graph)
#     #     # |> assign(open_tidbits: newtidbit_list)
#     #     |> push_graph(new_graph)

#     #     {:noreply, new_scene}
#     # end




#   def handle_call({:add_tidbit, tidbit}, _from, scene) do
#     #TODO note this is pretty arbitrary!! What if we don't want to add a HyperCard??
#     new_item = {HyperCard, tidbit, []}

#     new_state = scene.assigns.state
#     new_state = %{new_state|render_queue: new_state.render_queue ++ [new_item]}

#     new_scene = scene
#     |> assign(state: new_state)

#     # Logger.warn "IN THE LAYOUT LIST YES"

#     GenServer.cast(self(), :render_next_component)

#     {:reply, :ok, new_scene}
#   end

#   # def handle_call({:add_tidbit, tidbit}, _from, %{assigns: %{state: state}} = scene) do
#   #   #TODO note - I cant handle adding more than  tidbit yet, so that's why the above matches on active_components: [], and this is a catchall
#   #   Logger.warn "Trying to add tidbit, bad bad"
#   #   IO.inspect state.active_components
#   #   {:reply, :ok, scene}
#   # end

#   def handle_cast(:render_next_component, %{assigns: %{state: %{render_queue: []}}} = scene) do
#     Logger.debug "#{__MODULE__} ignoring a request to render a component, there's nothing to render"
#     {:noreply, scene}
#   end



#     # def render_push_graph(scene) do
#     #   new_scene = render(scene) # updates the graph
#     #   new_scene |> push_graph(new_scene.assigns.graph) # pushes the changes
#     # end

#   # Whenever a component successfully renders, it uses this to track how
#   # big it is
#   # def handle_cast({:component_callback, id, %{bounds: bounds} = data}, scene) do
#   #   # this callback is received when a component boots successfully -
#   #   # it register itself to this component (parent-child relationship,
#   #   # which ought to be able to handle props aswell!) including it's
#   #   # own size (since I want TidBits to grow organizally based on their
#   #   # size, and only wrap/clip in the most extreme circumstancses and/or
#   #   # boundary conditions)
#   #   IO.puts "#{inspect id} HEIGHT: #{inspect bounds}"
#   #   ic scene

#   #   new_state = scene.assigns.state
#   #   |> add_rendered_component({id, bounds})

#   #   GenServer.cast(self(), :render_next_component)

#   #   #TODO
#   #   # new_graph = scene.assigns.graph
#   #   # |>

#   #   new_scene = scene
#   #   |> assign(state: new_state)
#   #   # |> assign(open_tidbits: [{id, bounds}])

#   #   # now, this scene will be able to use this data to render the
#   #   # next TidBit in place!

#   #   {:noreply, scene}
#   # end

#   def handle_cast({:close_tidbit, title}, scene) do
#     #TODO here - we need to take the tidbit out of our list of active_components,
#     #            re-compute the graph from this new list & swap in the new graph
#     #            to update the display


#     #TODO so for now, cause I'm lazy, I'm just gonna take out the tidbit we
#     #     just closed & re-render everything from scratch
#     state = scene.assigns.state

#     new_active_components =
#       # state.active_components |> Enum.reject(& &1.title == title)
#       state.active_components
#       |> Enum.reject(fn {HyperCard, tidbit, _bounds} -> tidbit.title == title end)
#       # |> Enum.map(fn {HyperCard, tidbit, _bounds} -> tidbit end) # extract back out the main input, the TidBit, so we can just call re-render lmao

#       #lmao so I need to do this cause active_components have bounds, and actuall add_tidbit wants options
#       |> Enum.map(fn {HyperCard, tidbit, _bounds} -> {HyperCard, tidbit, []} end) # extract back out the main input, the TidBit, so we can just call re-render lmao

#     IO.inspect new_active_components, label: "WHATS LEFT"

#     new_state = %{state|active_components: [], render_queue: new_active_components}

#     new_graph =
#       Scenic.Graph.build()
#       |> Scenic.Primitives.group(fn graph ->
#           graph
#         end, [
#             #NOTE: We will scroll this pane around later on, and need to
#             #      add new TidBits to it with Modify
#             id: :river_pane, # Scenic required we register groups/components with a name
#             translate: state.scroll
#         ])

#     new_scene = scene
#     |> assign(graph: new_graph)
#     |> assign(state: new_state)
#     |> push_graph(new_graph)

#     #NOTE: My original idea was to send all these re-render messages at once,
#     #      the problem with that is that then they all render before any
#     #      of them have called back with their height!! The solution is
#     #      to only render one, let it go through it's cycle (calling back
#     #      with it's own bounds) and then if we still have things in the
#     #      render_queue, re-drawing those too
#     #Enum.each(new_active_components, fn _x -> GenServer.cast(self(), :render_next_component) end)
#     GenServer.cast(self(), :render_next_component)

#     {:noreply, new_scene}
#   end

#   #TODO this should be called - register_component_bounds/size or something
#   def handle_cast({:component_height, full_tidbit, bounds}, %{assigns: %{state: state}} = scene) do
#       # this callback is received when a component boots successfully -
#       # it register itself to this component (parent-child relationship,
#       # which ought to be able to handle props aswell!) including it's
#       # own size (since I want TidBits to grow organizally based on their
#       # size, and only wrap/clip in the most extreme circumstancses and/or
#       # boundary conditions)
#       # Logger.emergency "WERE GETTING CALLBACK"

#       new_state = %{state|
#                       active_components: state.active_components ++ [{HyperCard, full_tidbit, bounds}],
#                       # acc_height: state.acc_height+(component_height+@spacing_buffer)
#                     }

#       # IO.puts "HEIGHT: #{inspect bounds}"
#       # ic scene
#       # new_scene = scene
#       # |> assign(open_tidbits: [{id, bounds}])

#       # now, this scene will be able to use this data to render the
#       # next TidBit in place!

#       # if scene.assigns.state.render_queue == [] do
#       #   # nothing
#       #   :ok
#       # else
#         # Since one component just called back, we are ready to render
#         # the next one if there are any which need it
#         GenServer.cast(self(), :render_next_component)
#       # end

#       {:noreply, scene |> assign(state: new_state)}
#   end

#   def cap_position(%{assigns: %{frame: frame}} = scene, coord) do
#     height = calc_acc_height(scene)
#     if height > frame.dimensions.height do
#       coord
#       |> floor({0, -height + frame.dimensions.height / 2})
#       |> ceil({0, 0})
#     else
#       coord
#       |> floor(@min_position_cap)
#       |> ceil(@min_position_cap)
#     end
#   end

# end
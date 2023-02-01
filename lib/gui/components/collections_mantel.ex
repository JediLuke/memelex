defmodule Memelex.GUI.Components.CollectionsMantel do
    use Scenic.Component
    # use Flamelex.ProjectAliases
    require Logger
    alias ScenicWidgets.Core.Structs.Frame
    # alias Flamelex.GUI.Component.Memex
    # alias Flamelex.Fluxus.Reducers.Memex, as: RootReducer

    def validate(%{frame: %Frame{} = _f, state: _state} = data) do
        Logger.debug "#{__MODULE__} accepted params: #{inspect data}"
        {:ok, data}
    end

    def init(init_scene, args, opts) do
        Logger.debug "#{__MODULE__} initializing..."

        #TODO get the full list of TidBits here (just Titles)
    
        theme =
            (opts[:theme] || Scenic.Primitive.Style.Theme.preset(:light))
            |> Scenic.Primitive.Style.Theme.normalize()

        init_graph = Scenic.Graph.build()
        |> Scenic.Primitives.group(fn graph ->
            graph
            |> ScenicWidgets.SideNav.add_to_graph(%{
                frame: args.frame,
                state: construct_collections_nav_tree()
             }, id: {__MODULE__, :side_nav})
            # |> render_background(dimensions: args.frame.size, color: theme.background)
            # |> render_personal_tile()
            # |> render_main_memex_search()
            # |> render_lower_pane(args)
        end, [
            id: __MODULE__
            # translate: args.frame.pin
        ])

        # Flamelex.Utils.PubSub.subscribe(topic: :radix_state_change)

        new_scene = init_scene
        |> assign(graph: init_graph)
        |> assign(frame: args.frame)
        |> assign(state: args.state)
        |> push_graph(init_graph)
  
        {:ok, new_scene}
    end

    def construct_collections_nav_tree do
        all_tidbits = Memelex.My.Wiki.all()
        #TODO need to add indexes to each tidbit so we know what we clicked on (eventually)
        all_leaves = Enum.map(all_tidbits, fn t -> {:leaf, t.title, [], fn -> Memelex.My.Wiki.open(t) end} end)

        [{:closed_node, "All TidBits", [0], all_leaves}]
    end

    # def construct_file_tuples(root_dir, files) do
    #     files |> Enum.map(fn filename ->
    #        open_file_fn = fn -> Flamelex.API.Buffer.open(root_dir <> "/" <> filename) end
    #        {:leaf, t.title, open_file_fn}
    #     end)
    #  end

    # def construct_tuple_tree(nil) do
    #     []
    #  end
  
    #  def construct_tuple_tree(root_dir) when is_bitstring(root_dir) do
        
  
    #     files_and_dirs = File.ls!(root_dir) |> filter_ignored()
    #     {files, dirs} = split_files_and_directories(root_dir, files_and_dirs)
        
    #     sorted_dirs = sort_alphabetically(dirs)
    #     sorted_files = sort_alphabetically(files)
           
    #     dir_tuples = construct_dir_tuples(root_dir, sorted_dirs)
    #     file_tuples = construct_file_tuples(root_dir, sorted_files)
        
    #     dir_tuples ++ file_tuples # directories get put at the top
    #  end

    # def handle_event({:click, :open_random_tidbit_btn}, _from, scene) do
    #     Flamelex.Fluxus.action({RootReducer, {:open_tidbit, :random}})
    #     {:noreply, scene}
    # end

    # def handle_event({:click, :create_new_tidbit_btn}, _from, scene) do
    #     Flamelex.Fluxus.action({RootReducer, :new_tidbit})
    #     {:noreply, scene}
    # end

    # def handle_event({:value_changed, :text_pad, new_value}, _from, scene) do

    #     {:noreply, scene}
    # end
    

    # def handle_info({:radix_state_change, %{memex: %{sidebar: new_sidebar_state}}}, %{assigns: %{state: current_state}} = scene)
    #     when current_state != new_sidebar_state do
    #         Logger.warn "#{__MODULE__} updating due to a change in the Memex.SideBar state..."
    #         raise "cant do this yet"
    #         {:noreply, scene}
    # end

    # #NOTE: if `sidebar_state` matches, here, then they are the same, and no change in state has occured
    # def handle_info({:radix_state_change, %{memex: %{sidebar: sidebar_state}}}, %{assigns: %{state: sidebar_state}} = scene) do
    #     Logger.debug "#{__MODULE__} ignoring a :radix_state_change, it didn't change the Memex.Sidebar..."
    #     {:noreply, scene}
    # end

    # def render_background(graph, dimensions: size, color: color) do
    #     graph |> Scenic.Primitives.rect(size, fill: color)
    # end

    # def render_lower_pane(graph, %{frame: %Frame{} = sidebar_frame,
    #                                state: %{active_tab: :ctrl_panel,
    #                                         search: %{active?: false}}}) do
    #     lower_pane_frame = calc_lower_pane_frame(sidebar_frame)

    #     graph
    #     |> Scenic.Primitives.group(fn graph ->
    #         graph
    #         |> render_background(dimensions: lower_pane_frame.size, color: :green)
    #         |> Scenic.Components.button("Open random TidBit", id: :open_random_tidbit_btn, translate: {15, 20})
    #         |> Scenic.Components.button("Create new TidBit", id: :create_new_tidbit_btn, translate: {15, 75})
    #     end,
    #     id: {__MODULE__, :ctrl_panel},
    #     translate: lower_pane_frame.pin)
    # end

    # def calc_lower_pane_frame(%{top_left: %{x: x, y: y}, dimensions: %{width: w, height: h}}) do
    #     lower_pane_ratio = 0.72 # lower pane takes up bottom 72% of the sidebafr
    #     Frame.new(
    #         top_left: {0, (1-lower_pane_ratio)*h}, # move down 6 tenths of the height
    #         dimensions: {w, lower_pane_ratio*h}) # take up 4 tenths of the height
    # end


end
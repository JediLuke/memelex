defmodule Memelex.GUI.Component.Memex.SideBar do
    use Scenic.Component
    # use Flamelex.ProjectAliases
    require Logger
    alias ScenicWidgets.Core.Structs.Frame
    # alias Flamelex.GUI.Component.Memex
    # alias Flamelex.Fluxus.Reducers.Memex, as: MemexReducer

    def validate(%{frame: %Frame{} = _f, state: _state} = data) do
        Logger.debug "#{__MODULE__} accepted params: #{inspect data}"
        {:ok, data}
    end

    def init(init_scene, args, opts) do
        Logger.debug "#{__MODULE__} initializing..."
    
        theme =
            (opts[:theme] || Scenic.Primitive.Style.Theme.preset(:light))
            |> Scenic.Primitive.Style.Theme.normalize()

        init_graph = render(args)

        # Flamelex.Utils.PubSub.subscribe(topic: :radix_state_change)

        new_scene = init_scene
        |> assign(graph: init_graph)
        |> assign(frame: args.frame)
        |> assign(state: args.state)
        |> push_graph(init_graph)
  
        {:ok, new_scene}
    end

    def render(args) do
        Scenic.Graph.build()
        |> Scenic.Primitives.group(fn graph ->
            graph
            # |> ScenicWidgets.FrameBox.add_to_graph(%{frame: args.frame, fill: :gainsboro})
            |> Scenic.Primitives.rect({args.frame.dimens.width, (1-0.618)*args.frame.dimens.height}, fill: :violet)
            |> render_toolbar(args)
            # |> Scenic.Primitives.rect({32, 32}, fill: {:image, "icons/add.png"}, t: {50, 50})
            # |> Scenic.Primitives.rect({64, 64}, fill: {:image, "icons/close.png"}, t: {50, 50})
            # |> render_background(dimensions: args.frame.size, color: theme.background)
            # |> render_personal_tile()
            # |> render_main_memex_search()
            # |> render_lower_pane(args)
        end, [
            id: __MODULE__,
            translate: args.frame.pin
        ])
    end

    def render_toolbar(graph, args) do
        graph
        |> Scenic.Primitives.group(fn graph ->
            graph
            |> Scenic.Primitives.rect({args.frame.dimens.width, 50}, fill: :forest_green)
            |> render_tool_button(args)
            |> ScenicWidgets.IconButton.add_to_graph(%{frame: Frame.new(pin: {50, 0}, size: {50, 50}), hover_highlight?: false}, id: :cog)
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {100, 0}, size: {50, 50}), icon: "ionicons/black_32/edit.png"}, id: :edit)
            # |> Scenic.Primitives.rect({32, 32}, fill: {:image, "icons/add.png"}) 
        end, [
            translate: {0, ((1-0.618)*args.frame.dimens.height)-50}
        ])
    end

    def render_tool_button(graph, args) do
        graph
        |> Scenic.Primitives.rect({32, 32}, fill: {:image, "icons/add.png"}, translate: {(50-32)/2, (50-32)/2}) 
    end

    # def handle_event({:click, :open_random_tidbit_btn}, _from, scene) do
    #     Flamelex.Fluxus.action({MemexReducer, {:open_tidbit, :random}})
    #     {:noreply, scene}
    # end

    # def handle_event({:click, :create_new_tidbit_btn}, _from, scene) do
    #     Flamelex.Fluxus.action({MemexReducer, :new_tidbit})
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
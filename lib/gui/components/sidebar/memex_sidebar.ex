defmodule Memelex.GUI.Component.Memex.SideBar do
    use Scenic.Component
    # use Flamelex.ProjectAliases
    require Logger
    alias ScenicWidgets.Core.Structs.Frame
    # alias Flamelex.GUI.Component.Memex
    # alias Flamelex.Fluxus.Reducers.Memex, as: MemexReducer

    @split 0.618 # this is where we split the sidebar into upper & lower pane

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

        Flamelex.Utils.PubSub.subscribe(topic: :radix_state_change)

        new_scene = init_scene
        |> assign(graph: init_graph)
        |> assign(frame: args.frame)
        |> assign(state: args.state)
        |> push_graph(init_graph)
  
        {:ok, new_scene}
    end

    def handle_cast({:click, :add}, scene) do
        Memelex.My.Wiki.new()
        {:noreply, scene}
    end

    def handle_info({:radix_state_change, new_radix_state}, scene) do
        IO.puts "SIDEBARRRRRR"

        new_graph = render(%{
            frame: scene.assigns.frame,
            state: new_radix_state.memex
        })
    
        new_scene = scene
        |> assign(graph: new_graph)
        |> assign(state: new_radix_state.memex)
        |> push_graph(new_graph)

        {:noreply, new_scene}
    end

    def render(args) do
        Scenic.Graph.build()
        |> Scenic.Primitives.group(fn graph ->
            graph
            # |> ScenicWidgets.FrameBox.add_to_graph(%{frame: args.frame, fill: :gainsboro})
            |> Scenic.Primitives.rect({args.frame.dimens.width, (1-@split)*args.frame.dimens.height}, fill: :violet)
            |> render_toolbar(args)
            # |> Scenic.Primitives.rect({32, 32}, fill: {:image, "icons/add.png"}, t: {50, 50})
            # |> Scenic.Primitives.rect({64, 64}, fill: {:image, "icons/close.png"}, t: {50, 50})
            # |> render_background(dimensions: args.frame.size, color: theme.background)
            # |> render_personal_tile()
            # |> render_main_memex_search()
            |> render_lower_pane(args)
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
            # |> render_tool_button(args)
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {0, 0}, size: {50, 50}), icon: "ionicons/black_32/add-circle.png"}, id: :add)
            |> ScenicWidgets.IconButton.add_to_graph(%{frame: Frame.new(pin: {50, 0}, size: {50, 50}), hover_highlight?: false}, id: :cog)
            |> Memelex.GUI.Components.IconButton.add_to_graph(%{frame: Frame.new(pin: {100, 0}, size: {50, 50}), icon: "ionicons/black_32/search.png"}, id: :edit)
            # |> Scenic.Primitives.rect({32, 32}, fill: {:image, "icons/add.png"}) 
        end, [
            translate: {0, ((1-@split)*args.frame.dimens.height)-50}
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
    def render_lower_pane(graph, %{frame: sidebar_frame, state: %{story_river: %{open_tidbits: open_tidbits}}}) do
        lower_pane_frame = calc_lower_pane_frame(sidebar_frame)

        graph
        |> Scenic.Primitives.group(fn graph ->
            graph
            |> Scenic.Primitives.rect(lower_pane_frame.size, fill: :dark_gray)
            |> render_open_tidbits(lower_pane_frame, open_tidbits)
        end,
        id: {__MODULE__, :lower_pane},
        translate: lower_pane_frame.pin)
    end

    def calc_lower_pane_frame(%{coords: %{x: x, y: y}, dimens: %{width: w, height: h}}) do
        Frame.new(pin: {0, (1-@split)*h}, size: {w, @split*h})
    end

    # def render_open_tidbits(graph, _sidebar_frame, [] = _tidbit_list) do
    #     graph
    # end

    def render_open_tidbits(graph, sidebar_frame, tidbit_list) do
        {final_graph, _final_offset} = 
            Enum.reduce(tidbit_list, {graph, 0}, fn tidbit, {graph, offset_count} ->

                btn_height = 50 # this is the height of each button, get it from somewhere better than hard-coded

                button_frame =
                    Frame.new(%{pin: {0, offset_count*btn_height}, size: {sidebar_frame.dimens.width, btn_height}})

                new_graph = graph
                |> ScenicWidgets.TextButton.add_to_graph(%{
                    frame: button_frame,
                    text: tidbit.title <> " / " <> tidbit.uuid,
                    font: body_font()
                }, id: {__MODULE__, :lower_pane, :text_button, tidbit.uuid})

                {new_graph, offset_count+1}
            end)
        
        final_graph
    end

    defp body_font do
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
           ascent: ascent,
           descent: FontMetrics.descent(36, ibm_plex_mono_font_metrics)
        }
     end


end
defmodule Memelex.GUI.RootScene do
    @moduledoc false
    use Scenic.Scene
    require Logger

 
   def init(init_scene, _args, opts) do
      Logger.debug("#{__MODULE__} initializing...")

      # radix_state = Memelex.Fluxus.RadixStore.get()
      # init_graph = render(scene.viewport, radix_state)

      root_graph = render(init_scene.viewport)

      new_scene = init_scene
      # |> assign(graph: root_graph)
      |> push_graph(root_graph)

      Memelex.Utils.PubSub.subscribe(topic: :radix_state_change)

      # request_input(new_scene, [:viewport, :key, :cursor_scroll])
      request_input(new_scene, [:viewport])

      {:ok, new_scene}
   end

   def handle_input({:viewport, {:enter, _coords}}, context, scene) do
      Logger.debug "#{__MODULE__} ignoring `:viewport_enter`..."
      {:noreply, scene}
   end

   def handle_input({:viewport, {:exit, _coords}}, context, scene) do
      Logger.debug "#{__MODULE__} ignoring `:viewport_exit`..."
      {:noreply, scene}
   end

   def handle_input({:viewport, {:reshape, new_dimensions}}, _context, scene) do # e.g. of new_dimensions: {1025, 818}
      Logger.debug "#{__MODULE__} received :viewport :reshape, dim: #{inspect new_dimensions}"

      new_viewport = %{scene.viewport|size: new_dimensions}
      # Memelex.Fluxus.RadixStore.update_viewport(new_viewport)

      new_graph = render(new_viewport)

      new_scene = scene
      # |> assign(graph: new_graph)
      |> push_graph(new_graph)

      {:noreply, %{scene|viewport: new_viewport}}
   end
 
   def render(%Scenic.ViewPort{} = vp) do
      Scenic.Graph.build()
      |> Memelex.GUI.Components.Diary.add_to_graph(%{
         frame: ScenicWidgets.Core.Structs.Frame.new(vp),
         # radix_state: radix_state,
         # app: Flamelex
      })
   end
 end
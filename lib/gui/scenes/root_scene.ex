defmodule Memelex.GUI.RootScene do
    @moduledoc false
    use Scenic.Scene
    require Logger

 
   def init(init_scene, _args, opts) do
      Logger.debug("#{__MODULE__} initializing...")

      root_graph = render(init_scene.viewport)

      new_scene = init_scene
      |> push_graph(root_graph)

      # Memelex.Utils.PubSub.subscribe(topic: :radix_state_change)

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

   #TODO put viewport size in the state & only re-render if it changes, to get around the situation where Scenic sends itself a viewport resize every time it starts up...
   def handle_input({:viewport, {:reshape, new_dimensions}}, _context, scene) do # e.g. of new_dimensions: {1025, 818}
      Logger.debug "#{__MODULE__} received :viewport :reshape, dim: #{inspect new_dimensions}"

      # new_viewport = %{scene.viewport|size: new_dimensions}

      # NOTE - this causes render to be called twice upon boot, because
      # Scenic automatically sends itself a :reshape for some reason...
      
      #TODO don't re-draw, push a new frame down to the component...
      # new_graph = render(new_viewport)

      # new_scene = scene
      # |> push_graph(new_graph)

      # {:noreply, %{scene|viewport: new_viewport}}
      {:noreply, scene}
   end
 
   def render(%Scenic.ViewPort{} = vp) do

      IO.puts "RENRENRENRENREN"
      radix_state = Memelex.Fluxus.RadixStore.get()

      Scenic.Graph.build()
      |> Memelex.GUI.Components.MemDesk.add_to_graph(%{
         frame: ScenicWidgets.Core.Structs.Frame.new(vp),
         state: radix_state.memex,
         app: Memelex
      })
   end
 end
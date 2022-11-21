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
      |> assign(graph: root_graph)
      |> push_graph(root_graph)

      {:ok, new_scene}
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
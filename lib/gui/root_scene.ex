defmodule Memelex.GUI.RootScene do
    @moduledoc false
    use Scenic.Scene
    require Logger

 
   def init(init_scene, _args, opts) do
      Logger.debug("#{__MODULE__} initializing...")
      root_graph = Scenic.Graph.build()

      new_scene = init_scene
      |> assign(graph: root_graph)
      |> push_graph(root_graph)

      {:ok, new_scene}
   end
 
 end
defmodule Memelex.API.GUIControl do
   alias Memelex.Reducers.RootReducer

   def move_tidbit_focus(tidbit, new_focus) do
      #TODO no need to go through ROotReducer
      Memelex.Fluxus.action({RootReducer, {:move_tidbit_focus, tidbit, new_focus}})
   end

end
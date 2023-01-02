defmodule Memelex.Api.GUIControl do
   alias Memelex.Reducers.RootReducer

   def move_tidbit_focus(tidbit, new_focus) do
      Memelex.Fluxus.action({RootReducer, {:move_tidbit_focus, tidbit, new_focus}})
   end

end
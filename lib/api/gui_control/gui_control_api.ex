defmodule Memelex.API.GUIControl do
   alias Memelex.Reducers.TidbitReducer

   def move_tidbit_focus(tidbit, new_focus) do
      Memelex.Fluxus.action({TidbitReducer, {:move_tidbit_focus, tidbit, new_focus}})
   end

end
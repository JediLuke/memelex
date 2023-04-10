defmodule Memelex.GUI.Control do
   alias Memelex.Fluxus.Reducers.TidbitReducer

   def move_tidbit_focus(tidbit, new_focus) do
      Memelex.Fluxus.action({TidbitReducer, {:move_tidbit_focus, tidbit, new_focus}})
   end

   def move_cursor(tidbit, section, delta) when section in [:title, :body] do
      Memelex.Fluxus.action({TidbitReducer, {:move_cursor, tidbit, section, delta}})
   end
end

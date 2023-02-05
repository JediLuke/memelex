defmodule Memelex.GUI.Control do
   alias Memelex.Reducers.TidbitReducer

   def move_tidbit_focus(tidbit, new_focus) do
      Memelex.Fluxus.action({TidbitReducer, {:move_tidbit_focus, tidbit, new_focus}})
   end

end

#TODO surely here we want to do the same kind of pattern we use for dispatching actions?? It's fundamentally a kind of reducer??

# defmodule Memelex.GUI.Control do
#    alias Memelex.Reducers.TidbitReducer

#    def move_tidbit_focus(tidbit, new_focus) do
#       Memelex.Fluxus.action({TidbitReducer, {:move_tidbit_focus, tidbit, new_focus}})
#    end

# end
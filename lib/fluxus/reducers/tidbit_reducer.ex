defmodule Memelex.Reducers.TidbitReducer do

   def process(radix_state, {:move_tidbit_focus, tidbit, new_focus}) when new_focus in [:title, :body] do
      new_radix_state =
         radix_state |> update_tidbit(tidbit, focus: new_focus)

      {:ok, new_radix_state}
   end

   def update_tidbit(radix_state, %{uuid: tidbit_uuid}, modification) do
      new_tidbit_list =
         radix_state.memex.story_river.open_tidbits
         |> Enum.map(fn
               %{uuid: ^tidbit_uuid} = t ->
                  t |> modify_tidbit(modification)
               other_tidbit ->
                  other_tidbit # no edit
            end)

      radix_state |> put_in([:memex, :story_river, :open_tidbits], new_tidbit_list)
   end

   def modify_tidbit(tidbit, focus: new_focus) do
      put_in(tidbit.gui.focus, new_focus)
   end

end
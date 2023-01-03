defmodule Memelex.Reducers.TidbitReducer do

   #TODO condense this into just :update
   def process(radix_state, {:move_tidbit_focus, tidbit, new_focus}) when new_focus in [:title, :body] do
      new_radix_state = radix_state
      |> update(tidbit, focus: new_focus)

      {:ok, new_radix_state}
   end

   def process(radix_state, {:update, tidbit, updates}) do
      new_radix_state = radix_state |> update(tidbit, updates)
      {:ok, new_radix_state}
   end

   def update(radix_state, %{uuid: tidbit_uuid}, modification) do
      new_tidbit_list =
         radix_state.memex.story_river.open_tidbits
         |> Enum.map(fn
               %{uuid: ^tidbit_uuid} = t ->
                  t |> modify(modification)
               other_tidbit ->
                  other_tidbit # no edit
            end)

      radix_state |> put_in([:memex, :story_river, :open_tidbits], new_tidbit_list)
   end

   def modify(%{gui: %{mode: :edit}} = tidbit, focus: new_focus) do
      put_in(tidbit.gui.focus, new_focus)
   end

   def modify(tidbit, {:append_to_title, text}) do
      title_cursor = tidbit.gui.cursors.title
      put_in(tidbit.gui.cursors.title, move_cursor(title_cursor, {:columns_right, String.length(text)}))
      |> Map.put(:title, tidbit.title <> text)
   end

   def modify(tidbit, {:append_to_body, text}) do
      body_cursor = tidbit.gui.cursors.body
      put_in(tidbit.gui.cursors.body, move_cursor(body_cursor, {:columns_right, String.length(text)}))
      |> Map.put(:data, tidbit.data <> text)
   end

   def move_cursor(cursor, args) do
      ScenicWidgets.TextPad.CursorCaret.move_cursor(cursor, args)
   end

end
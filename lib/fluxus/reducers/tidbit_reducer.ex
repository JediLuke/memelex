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
         radix_state.story_river.open_tidbits
         |> Enum.map(fn
               %{uuid: ^tidbit_uuid} = t ->
                  t |> modify(modification)
               other_tidbit ->
                  other_tidbit # no edit
            end)

      radix_state |> put_in([:story_river, :open_tidbits], new_tidbit_list)
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

   def modify(%{gui: %{mode: :edit, focus: :title}} = tidbit, {:backspace, x, :at_cursor}) do

      {new_title, new_cursor} =
         ScenicWidgets.TextPad.backspace(tidbit.title, tidbit.gui.cursors.title, x, :at_cursor)

      put_in(tidbit.gui.cursors.title, new_cursor)
      |> Map.put(:title, new_title)
   end

   def modify(%{gui: %{mode: :edit, focus: :body}} = tidbit, {:backspace, x, :at_cursor}) do

      {new_data, new_cursor} =
         ScenicWidgets.TextPad.backspace(tidbit.data, tidbit.gui.cursors.body, x, :at_cursor)

      put_in(tidbit.gui.cursors.body, new_cursor)
      |> Map.put(:data, new_data)
   end

   defp move_cursor(cursor, args) do
      ScenicWidgets.TextPad.CursorCaret.move_cursor(cursor, args)
   end

end
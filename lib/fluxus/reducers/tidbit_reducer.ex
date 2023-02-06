defmodule Memelex.Reducers.TidbitReducer do
   require Logger


   def process(radix_state, {:create_tidbit, %Memelex.TidBit{} = new_tidbit}) do
      new_tidbit = new_tidbit
      |> Map.merge(%{
         gui: %{
            mode: :edit,
            saved_content: nil,
            focus: :title,
            cursors: %{
               title: %{line: 1, col: String.length(new_tidbit.title)},
               body: %{line: 1, col: 1}
            }
         }
      })
   
      new_radix_state =
         radix_state
         |> put_in(
            [:story_river, :open_tidbits],
            radix_state.story_river.open_tidbits ++ [new_tidbit]
         )
         |> put_in(
            [:story_river, :focussed_tidbit],
            new_tidbit.uuid
         )
  
      {:ok, new_radix_state}
   end

   def process(radix_state, {:open_tidbit, t}) do
      # tidbit = fetch_tidbit(t)

      #TODO we need to ensure no titles contain newoine chars, or if we do, then we need to allow ourselves to handle it - probably we should be able to just say "put the cursor in final position" & let TextPad figure it out...
      opening_cursors = %{
         # we need the +1 because a string of length zero is still position 1 in our editor
         title: %{line: 1, col: String.length(t.title)+1},
         body: %{line: 1, col: 1}
      }

      #TODO need to handle :ok/:error when we fetch
      new_tidbit = fetch_tidbit(t)
      |> Map.merge(%{
         gui: %{
            mode: :normal,
            focus: :title,
            cursors: opening_cursors
         }
      })

      new_radix_state =
         radix_state
         |> put_in(
            [:story_river, :open_tidbits],
            radix_state.story_river.open_tidbits ++ [new_tidbit]
         )
         |> put_in(
            [:story_river, :focussed_tidbit],
            new_tidbit.uuid
         )
  
      {:ok, new_radix_state}
   end

   def process(radix_state, {:edit_tidbit, %{tidbit_uuid: t_uuid}}) do
      Logger.warn "REMINDER we need to ACTUALLY SAVE the TidBit in the DB..."
      IO.puts "Here we need to save the TidBit & Update RadixState..."

      updated_tidbits = radix_state.story_river.open_tidbits |> Enum.map(fn
        %{uuid: ^t_uuid} = tidbit ->

            IO.puts "EDITING THIS TIDBIT #{inspect tidbit}"

            tidbit_gui = tidbit.gui
            new_tidbit_gui = tidbit_gui |> Map.merge(%{
               mode: :edit,
               focus: :title,
               # stash the current saved contents, incase we discard these edits
               stash: %{
                  title: tidbit.title,
                  body: tidbit.data
               }
            })
            tidbit |> Map.merge(%{gui: new_tidbit_gui})
         other_tidbit ->
            other_tidbit # make no changes to other TidBits...
      end)

      new_radix_state = radix_state
      |> put_in([:story_river, :open_tidbits], updated_tidbits)
      |> put_in([:story_river, :focussed_tidbit], t_uuid)

      {:ok, new_radix_state}
   end
   
   def process(radix_state, {:discard_changes, %{tidbit_uuid: tidbit_uuid}}) do
      # new_radix_state = radix_state |> update(tidbit, updates)


      # fetch TidBit from memory
      updated_tidbits = radix_state.story_river.open_tidbits |> Enum.map(fn
         %{uuid: ^tidbit_uuid, gui: %{stash: %{title: old_title, body: old_body}}} = tidbit ->
            #  {:ok, _saved_tidbit} = GenServer.call(Memelex.WikiServer, {:save_tidbit, tidbit})
            #  put_in(tidbit.gui.mode, :normal)
            t = %{tidbit|title: old_title, data: old_body}
            put_in(t.gui.mode, :normal)
          other_tidbit ->
             other_tidbit # make no changes to other TidBits...
       end)

      # check saved_content, if it's nil then delete the TidBit

      # if it's not nil, reset changes back to that saved content

      new_radix_state = radix_state
      |> put_in([:story_river, :open_tidbits], updated_tidbits)

      {:ok, new_radix_state}
   end

   def process(radix_state, {:save_tidbit, %{tidbit_uuid: tidbit_uuid}}) do

      updated_tidbits = radix_state.story_river.open_tidbits |> Enum.map(fn
        %{uuid: ^tidbit_uuid} = tidbit ->
            {:ok, _saved_tidbit} = GenServer.call(Memelex.WikiServer, {:save_tidbit, tidbit})
            put_in(tidbit.gui.mode, :normal)
         other_tidbit ->
            other_tidbit # make no changes to other TidBits...
      end)
   
      new_radix_state = radix_state
      |> put_in([:story_river, :open_tidbits], updated_tidbits)

      {:ok, new_radix_state}
   end

   def process(radix_state, {:close_tidbit, %{tidbit_uuid: tidbit_uuid}}) do
      updated_tidbits =
         radix_state.story_river.open_tidbits
         |> Enum.reject(& &1.uuid == tidbit_uuid)

      new_radix_state = radix_state
      |> put_in([:story_river, :open_tidbits], updated_tidbits)
      |> put_in([:story_river, :focussed_tidbit], nil)

      {:ok, new_radix_state}
   end

   def process(radix_state, {:move_tidbit_focus, tidbit, new_focus}) when new_focus in [:title, :body] do
      new_radix_state = radix_state
      |> update(tidbit, focus: new_focus)

      {:ok, new_radix_state}
   end

   # def process(radix_state, {:move_cursor, %Memelex.TidBit{} = tidbit, section, delta}) when section in [:title, :body] do
   def process(radix_state, {:move_cursor, tidbit, section, delta}) when section in [:title, :body] do
      new_radix_state = radix_state
      |> update(tidbit, move_cursor: {section, delta})

      {:ok, new_radix_state}
   end

   # def process(rx, a) do
   #    dbg()
   # end

   #NOTE - the use of :update -- (THIS IS THE FUTURE!!)
   # instead of having all those individual calls, just keep the same functon & pattern match on the modification in modify/2
   def process(radix_state, {:update, tidbit, updates}) do
      new_radix_state = radix_state |> update(tidbit, updates)
      {:ok, new_radix_state}
   end

   #TODO refactor all below here, each function in this moduole needs to be process/2 or else move it into another module

   def fetch_tidbit(t) do
      {:ok, full_tidbit} = GenServer.call(Memelex.WikiServer, {:fetch, t})
      full_tidbit
   end

   def update(radix_state, %Memelex.TidBit{uuid: tidbit_uuid}, modification) do
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
         QuillEx.Utils.EditingText.backspace(tidbit.data, tidbit.gui.cursors.body, x, :at_cursor)

      put_in(tidbit.gui.cursors.body, new_cursor)
      |> Map.put(:data, new_data)
   end

   def modify(%{gui: %{mode: :edit, focus: :title}} = tidbit, {:insert_text, txt, :at_cursor}) do
      {new_text, new_cursor} =
         QuillEx.Utils.EditingText.insert_text_at_cursor(%{
            old_text: tidbit.title,
            cursor: tidbit.gui.cursors.title,
            text_2_insert: txt
         })

      put_in(tidbit.gui.cursors.title, new_cursor)
      |> Map.put(:title, new_text)
   end

   def modify(tidbit, {:insert_text, t, in: :body, at: {:cursor, c}}) do
      {new_data, new_cursor} =
         QuillEx.Utils.EditingText.insert_text_at_cursor(%{
            old_text: tidbit.data,
            cursor: c,
            text_2_insert: t
         })

      put_in(tidbit.gui.cursors.body, new_cursor)
      |> Map.put(:data, new_data)
   end

   def modify(tidbit, [move_cursor: {:body, delta}]) do
      current_cursor = tidbit.gui.cursors.body
      
      new_cursor = QuillEx.Utils.EditingText.move_cursor(tidbit.data, current_cursor, delta)

      put_in(tidbit.gui.cursors.body, new_cursor)
   end

   def modify(tidbit, modification) do
      Logger.error "Unrecognised modification: #{inspect modification}. No TidBit modification occured..."
      tidbit
   end

   defp move_cursor(cursor, args) do
      ScenicWidgets.TextPad.CursorCaret.move_cursor(cursor, args)
   end

end
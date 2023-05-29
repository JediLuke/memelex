defmodule Memelex.Fluxus.Reducers.TidbitReducer do
   require Logger
   alias Memelex.Fluxus.Reducers.TidbitReducer.Utils


   # #NOTE - the use of :update -- (THIS IS THE FUTURE!!)
   # instead of having all those individual calls, just keep the same functon & pattern match on the modification in modify/2
   # def process(radix_state, {:update, tidbit, updates}) do
   #    new_radix_state = radix_state |> update(tidbit, updates)
   #    {:ok, new_radix_state}
   # end
   def process(radix_state, {:edit_tidbit, %Memelex.TidBit{} = tidbit, modification}) do
      {:ok, radix_state |> Utils.apply_mod(tidbit, modification)}
   end

   def process(radix_state, {:update_tidbit, %Memelex.TidBit{} = t, modification}) do
      # this one saves it in the WikiServer, so it's a proper update, not just an edit (which only occures in the RadixState memory)
      modified_t = Memelex.TidBit.modify(t, modification)
      process(radix_state, {:save_tidbit, modified_t})
   end

   #TODO here ok so we get a whole TidBit struct, it deserves to be saved when we create it. Even if we put it right back into edit mode...

   # See we still need *some* way to distinguish because we need to know whether or not to open this TidBit up in the `OpenTidbits` (whether or not memex is the active app) and what mode to open it up in (edit or normal)
   def process(radix_state, {act_of_creation, %Memelex.TidBit{} = new_tidbit})
      when act_of_creation in [:add_tidbit, :new_tidbit] do

      if act_of_creation == :add_tidbit do
         {:ok, _saved_t} = GenServer.call(Memelex.WikiServer, {:save_tidbit, new_tidbit})
      end

      start_gui_mode = case act_of_creation do
         :add_tidbit -> :normal
         :new_tidbit -> :edit
      end

      new_tidbit = new_tidbit
      |> Map.merge(%{
         gui: %{
            mode: start_gui_mode,
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

   def process(%{story_river: %{focussed_tidbit: t_uuid}} = radix_state, {:open_tidbit, %{uuid: t_uuid}}) do
      # NOTE - it's possible that the above code, while executing, called
      # Wiki.new, which will auto-magically cause it to be rendered in the
      # memex & potentially even the Editor... for this reason we are going to
      # need a clause which handles :open_tidbit getting called on a tidbit which
      # is already open, which shouldn't be such a hack really as we can just
      # explicitely ignore it

      # clause where we need to open a tidbit, and it already exists as gui mode
      :ignore
   end

   #TODO does this mean always open a tidbit which exists on disk, which exists in WikiServer memory, or which exists in the GUI?>>?>?
   def process(radix_state, {:open_tidbit, t}) do
      case Utils.fetch_tidbit(t) do
         nil ->
            {:error, "No such TidBit `#{t.title}` exists in the Memex."}

         %Memelex.TidBit{} = t ->
            new_tidbit =
               Map.merge(t, %{
                  gui: %{
                     mode: :normal,
                     focus: :title,
                     cursors: %{
                        #TODO we need to ensure no titles contain newoine chars, or if we do, then we need to allow ourselves to handle it - probably we should be able to just say "put the cursor in final position" & let TextPad figure it out...
                        # we need the +1 because a string of length zero is still position 1 in our editor
                        title: %{line: 1, col: String.length(t.title)+1},
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
   end

   def process(radix_state, {:set_gui_mode, new_mode, %{tidbit_uuid: t_uuid}}) do
      updated_tidbits =
         radix_state.story_river.open_tidbits
         |> Enum.map(fn
            %{uuid: ^t_uuid} = t ->
               Memelex.TidBit.modify(t, {:set_gui_mode, new_mode, focus: :title})

            other_tidbit ->
               other_tidbit # make no changes to other TidBits...
         end)

      new_radix_state = radix_state
      |> put_in([:story_river, :open_tidbits], updated_tidbits)
      |> put_in([:story_river, :focussed_tidbit], t_uuid)

      {:ok, new_radix_state}
   end

   def process(radix_state, {:discard_changes, %{tidbit_uuid: tidbit_uuid}}) do

      # check saved_content, if it's nil then delete the TidBit
      # if it's not nil, reset changes back to that saved content
      updated_tidbits =
         radix_state.story_river.open_tidbits
         |> Enum.map(fn
            %{uuid: ^tidbit_uuid, gui: %{stash: %{title: old_title, body: old_body}}} = tidbit ->
               t = %{tidbit|title: old_title, data: old_body}
               put_in(t.gui.mode, :normal)
            %{uuid: ^tidbit_uuid} = tidbit ->
               :discarded_unsaved_tidbit
            other_tidbit ->
               other_tidbit # make no changes to other TidBits...
         end)
         |> Enum.reject(& &1 == :discarded_unsaved_tidbit)

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

   def process(radix_state, {:save_tidbit, %{tidbit_uuid: t_uuid}}) do
      #TODO we implicitely assume if you're saving a tidbit with just the tidbit_uuid, and not the whole struct, then it must be an open tidbit - otherwise we have nothing to save anyway...
      # however we should handle the case more gracefully than this pattern-match!
      %Memelex.TidBit{} = t =
         radix_state.story_river.open_tidbits
         |> Utils.filter_find_tidbit(%{tidbit_uuid: t_uuid})

      {:ok, new_t} = GenServer.call(Memelex.WikiServer, {:save_tidbit, t})

      {:ok, radix_state |> Utils.apply_mod(new_t, {:gui, :mode, :normal})}
   end
   
   def process(radix_state, {:save_tidbit, %Memelex.TidBit{} = t}) do
      {:ok, new_t} = GenServer.call(Memelex.WikiServer, {:save_tidbit, t})
      {:ok, radix_state |> Utils.apply_mod(new_t, {:gui, :mode, :normal})}
   end

   def process(radix_state, {:save_tidbit, %{tidbit_uuid: t_uuid}}) when is_bitstring(t_uuid) do
      
      # If this tidbit_uuid doesn't exist in RadixState memory, just raise
      if not Enum.any?(radix_state.story_river.open_tidbits, & &1.uuid == t_uuid) do
         raise "Could not save. No open TidBits with uuid: #{t_uuid}"
      end

      updated_tidbits = radix_state.story_river.open_tidbits |> Enum.map(fn
        %{uuid: ^t_uuid} = tidbit ->
            {:ok, _saved_tidbit} = GenServer.call(Memelex.WikiServer, {:save_tidbit, tidbit})
            put_in(tidbit.gui.mode, :normal)
         other_tidbit ->
            other_tidbit # make no changes to other TidBits...
      end)
   
      new_radix_state = radix_state
      |> put_in([:story_river, :open_tidbits], updated_tidbits)

      {:ok, new_radix_state}
   end

   def process(radix_state, {:delete_tidbit, %{tidbit_uuid: t_uuid} = t_lookup}) do
      
      #TODO we should defer to the WikiServer here, since deleting involves the disk
      updated_tidbits =
         radix_state.story_river.open_tidbits
         |> Enum.map(fn
            %{uuid: ^t_uuid} = tidbit ->
               :deleted = GenServer.call(Memelex.WikiServer, {:delete_tidbit, tidbit})
            other_tidbit ->
               other_tidbit # make no changes to other TidBits...
         end)
         |> Enum.reject(& &1 == :deleted)
   
      new_radix_state = radix_state
      |> put_in([:story_river, :open_tidbits], updated_tidbits)

      {:ok, new_radix_state}
   end

   def process(radix_state, {:move_tidbit_focus, tidbit, new_focus}) when new_focus in [:title, :body] do
      new_radix_state = radix_state
      |> Utils.apply_mod(tidbit, focus: new_focus)

      {:ok, new_radix_state}
   end

   def process(radix_state, {:move_cursor, tidbit, section, delta})
      when section in [:title, :body] do
         {:ok, radix_state |> Utils.apply_mod(tidbit, {:move_cursor, section, delta})}
   end



end
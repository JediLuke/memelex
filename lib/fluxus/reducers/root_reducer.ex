defmodule Memelex.Reducers.RootReducer do
   require Logger
   alias Memelex.Reducers.TidbitReducer

   def process(%{memex: %{story_river: %{open_tidbits: tidbits}}} = radix_state, {:save_tidbit, %{tidbit_uuid: tidbit_uuid}}) do
      Logger.warn "REMINDER we need to ACTUALLY SAVE the TidBit in the DB..."
      IO.puts "Here we need to save the TidBit & Update RadixState..."

      updated_tidbits = tidbits |> Enum.map(fn
        %{uuid: ^tidbit_uuid} = tidbit ->
            # tidbit |> put_in([:gui, :mode], :normal)
            tidbit_gui = tidbit.gui
            new_tidbit_gui = tidbit_gui |> Map.merge(%{mode: :normal})
            tidbit |> Map.merge(%{gui: new_tidbit_gui})
         other_tidbit ->
            other_tidbit # make no changes to other TidBits...
      end)
   
      {:ok, radix_state |> put_in([:memex, :story_river, :open_tidbits], updated_tidbits)}
   end

   def process(%{memex: %{story_river: %{open_tidbits: tidbits}}} = radix_state, {:edit_tidbit, %{tidbit_uuid: tidbit_uuid}}) do
      Logger.warn "REMINDER we need to ACTUALLY SAVE the TidBit in the DB..."
      IO.puts "Here we need to save the TidBit & Update RadixState..."

      updated_tidbits = tidbits |> Enum.map(fn
        %{uuid: ^tidbit_uuid} = tidbit ->
            # tidbit |> put_in([:gui, :mode], :normal)
            tidbit_gui = tidbit.gui
            new_tidbit_gui = tidbit_gui |> Map.merge(%{mode: :edit, focus: :title})
            tidbit |> Map.merge(%{gui: new_tidbit_gui})
         other_tidbit ->
            other_tidbit # make no changes to other TidBits...
      end)
   
      {:ok, radix_state |> put_in([:memex, :story_river, :open_tidbits], updated_tidbits)}
   end

   def process(radix_state, {:move_tidbit_focus, _tidbit, _new_focus} = action) do
      TidbitReducer.process(radix_state, action)
   end

   def process(%{memex: %{story_river: %{open_tidbits: tidbits}}} = radix_state, {:close_tidbit, %{tidbit_uuid: tidbit_uuid}}) do
      updated_tidbits = tidbits |> Enum.reject(& &1.uuid == tidbit_uuid)
      {:ok, radix_state |> put_in([:memex, :story_river, :open_tidbits], updated_tidbits)}
   end

end
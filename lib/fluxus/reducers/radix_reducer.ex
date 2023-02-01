defmodule Memelex.Fluxus.Reducers.RadixReducer do
   require Logger
   alias Memelex.Reducers.TidbitReducer

   #TODO Memelex needs its own ActionListener now :S

   def process(radix_state, {:create_tidbit, %Memelex.TidBit{} = new_tidbit}) do

      new_tidbit = new_tidbit
      |> Map.merge(%{
         gui: %{
            mode: :edit,
            focus: :title,
            cursors: %{
               title: %{line: 1, col: 1},
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
      tidbit = fetch_tidbit(t)

      new_tidbit = fetch_tidbit(t)
      |> Map.merge(%{
         gui: %{
            mode: :normal,
            focus: :title,
            cursors: %{
               title: %{line: 1, col: 1},
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

   def process(radix_state, {:edit_tidbit, %{tidbit_uuid: tidbit_uuid}}) do
      Logger.warn "REMINDER we need to ACTUALLY SAVE the TidBit in the DB..."
      IO.puts "Here we need to save the TidBit & Update RadixState..."

      updated_tidbits = radix_state.story_river.open_tidbits |> Enum.map(fn
        %{uuid: ^tidbit_uuid} = tidbit ->
            tidbit_gui = tidbit.gui
            new_tidbit_gui = tidbit_gui |> Map.merge(%{mode: :edit, focus: :title})
            tidbit |> Map.merge(%{gui: new_tidbit_gui})
         other_tidbit ->
            other_tidbit # make no changes to other TidBits...
      end)

      new_radix_state = radix_state
      |> put_in([:story_river, :open_tidbits], updated_tidbits)
      |> put_in([:story_river, :focussed_tidbit], tidbit_uuid)

      {:ok, new_radix_state}
   end

   def process(radix_state, {:move_tidbit_focus, _tidbit, _new_focus} = action) do
      TidbitReducer.process(radix_state, action)
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

      #TODO clean this up, move to it's own module (or rather move everything else to a different module)
      def process(radix_state, {reducer, action}) when is_atom(reducer) do
         try do
            reducer.process(radix_state, action)
         rescue
            e in FunctionClauseError ->
            IO.inspect e
            {:error, "#{__MODULE__} -- Reducer `#{inspect reducer}` could not match action: #{inspect action}"}
         end
      end
      

   def process(state, a) do
      dbg()
   end

   def fetch_tidbit(t) do
      {:ok, full_tidbit} = GenServer.call(Memelex.WikiServer, {:fetch, t})
      full_tidbit
   end
end
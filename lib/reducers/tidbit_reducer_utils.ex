defmodule Memelex.Fluxus.Reducers.TidbitReducer.Utils do

    @doc """
    Updates the radix_state with specific modifications to a TidBit.
    """
    def apply_mod(radix_state, %Memelex.TidBit{uuid: tidbit_uuid}, modification) do

        # find the specific tidbit in the radix_state & apply the modification to it
        new_tidbit_list =
            radix_state.story_river.open_tidbits
            |> Enum.map(fn
                    %{uuid: ^tidbit_uuid} = t ->
                        Memelex.TidBit.modify(t, modification)
                    other_tidbit ->
                        other_tidbit # no edit
                end)

        put_in(radix_state.story_river.open_tidbits, new_tidbit_list)
    end

    def filter_find_tidbit(tidbit_list, %{tidbit_uuid: t_uuid}) when is_bitstring(t_uuid) do
        Enum.find(tidbit_list, & &1.uuid == t_uuid) || raise "Could not find an open TidBit with uuid: #{t_uuid}"
    end


 # defp move_cursor(cursor, args) do
 #    ScenicWidgets.TextPad.CursorCaret.move_cursor(cursor, args)
 # end

    def fetch_tidbit(t) do
        {:ok, full_tidbit} = GenServer.call(Memelex.WikiServer, {:fetch, t})
        full_tidbit
     end

end
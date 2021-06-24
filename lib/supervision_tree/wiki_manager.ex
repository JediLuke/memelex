defmodule Memex.Env.WikiManager do
  use GenServer
  require Logger
  alias Memex.Utils


  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: Memex.Env.WikiManager)
  end

  ##TODO this process should be backing up the wiki to disc (periodiclly?)

  def init(env) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, env, {:continue, :load_wiki_from_disk}}
  end


  def handle_continue(:load_wiki_from_disk, state) do
    tidbit_list =
      wiki_file(state)
      |> Utils.FileIO.read_maplist()
      |> convert_to_tidbit_structs()

    Logger.info "#{Enum.count(tidbit_list)} TidBits loaded from the Wiki file."
    {:noreply, state |> Map.merge(%{wiki: tidbit_list})}
  end

  def handle_call(:can_i_get_a_list_of_all_tidbits_plz, _from, state) do
    {:reply, {:ok, state.wiki}, state}
  end

  def handle_call({:new_tidbit, %Memex.TidBit{} = t}, _from, state) do
    new_wiki = state.wiki ++ [t]
    wiki_file(state) |> Utils.FileIO.write_maplist(new_wiki)
    {:reply, {:ok, t}, %{state|wiki: new_wiki}}
  end

  def handle_call(:whats_the_file_we_store_passwords_in_again?, _from, state) do
    {:reply, {:ok, "#{state["memex_directory"]}/passwords.txt"}, state}
  end

  def handle_call({:update_tidbit, tidbit, updates}, _from, state) do

    is_this_the_tidbit_were_looking_for? =
      fn(t) -> t.title == tidbit.title and t.uuid == tidbit.uuid end
    
    tidbit =
      state.wiki |> Enum.find(is_this_the_tidbit_were_looking_for?)

    if tidbit == [] do
      {:reply, {:error, "could not find a Tidbit with title: #{inspect tidbit.title}"}, state}
    else

      updated_tidbit =
        tidbit |> Map.merge(updates) #TODO need more validation on these updates! Could overwrite any field here right now!
      wiki_with_old_entry_removed =
        state.wiki |> Enum.reject(is_this_the_tidbit_were_looking_for?)
      new_wiki =
        wiki_with_old_entry_removed ++ [updated_tidbit]

      wiki_file(state) |> Utils.FileIO.write_maplist(new_wiki)

      {:reply, {:ok, updated_tidbit}, %{state|wiki: new_wiki}}
    end
  end


  defp wiki_file(%{"memex_directory" => dir}) do
    "#{dir}/tidbit-db.json"
  end

  defp convert_to_tidbit_structs(list_of_tidbits_as_maps) do
    list_of_tidbits_as_maps
    |> Enum.map(
         fn(tidbit_map_with_string_keys) ->
              struct_params =
                  tidbit_map_with_string_keys
                  |> convert_to_keyword_list()
              Kernel.struct!(Memex.TidBit, struct_params)
         end)
  end
  
  defp convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    map |> Keyword.new(fn {k,v} -> {String.to_existing_atom(k),v} end)
  end
end
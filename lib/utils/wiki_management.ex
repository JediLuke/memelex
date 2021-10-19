defmodule Memex.Utils.WikiManagement do


  @similarity_cutoff 0.72


  def new_tidbit(%{state: state, tidbit: t}) do
    title_already_exists? =
      state.wiki |> Enum.any?(fn tidbit -> tidbit.title == t.title end)

    if title_already_exists? do
      {:error, "this tidbit already exists"}
    else
      new_wiki = state.wiki ++ [t]
      wiki_file(state) |> Memex.Utils.FileIO.write_maplist(new_wiki)
      {:ok, new_wiki}
    end
  end

  def add_tag(%{tag: tag, state: state, tidbit: %Memex.TidBit{} = tidbit})
    when is_bitstring(tag) do
    
      is_this_the_tidbit_were_looking_for? =
        fn(t) -> t.title == tidbit.title and t.uuid == tidbit.uuid end
        
      tidbit =
        state.wiki |> Enum.find(is_this_the_tidbit_were_looking_for?)

      if tidbit == [] do
        {:error, "Could not find a Tidbit with the title: #{inspect tidbit.title}"}
      else
        updated_tidbit =
          tidbit
          |> Map.merge(%{tags: tidbit.tags ++ [tag]}) #TODO need more validation on these updates! Could overwrite any field here right now!
          |> Map.merge(%{modified: DateTime.utc_now(), modifier: "JediLuke"}) #TODO get real values for these
      
        wiki_with_old_entry_removed =
          state.wiki |> Enum.reject(is_this_the_tidbit_were_looking_for?)
      
        new_wiki =
          wiki_with_old_entry_removed ++ [updated_tidbit]

        #TODO this seems to be working, but better to just overwrite the file again & refresh
        wiki_file(state) |> Memex.Utils.FileIO.write_maplist(new_wiki)

        {:ok, updated_tidbit, %{state|wiki: new_wiki}}
      end
  end


  def update_tidbit(%{state: state, tidbit: tidbit, updates: updates}) do

    is_this_the_tidbit_were_looking_for? =
      fn(t) -> t.title == tidbit.title and t.uuid == tidbit.uuid end
    
    tidbit =
      state.wiki |> Enum.find(:not_found, is_this_the_tidbit_were_looking_for?)

    if tidbit == :not_found do
      {:error, "Could not find a Tidbit with the title: #{inspect tidbit.title}"}
    else

      updated_tidbit =
        tidbit
        |> Map.merge(updates) #TODO need more validation on these updates! Could overwrite any field here right now!
        |> Map.merge(%{modified: DateTime.utc_now(), modifier: "JediLuke"}) #TODO get real values for these
      
      wiki_with_old_entry_removed =
        state.wiki |> Enum.reject(is_this_the_tidbit_were_looking_for?)
      
      new_wiki =
        wiki_with_old_entry_removed ++ [updated_tidbit]

      wiki_file(state) |> Memex.Utils.FileIO.write_maplist(new_wiki)

      {:ok, updated_tidbit, new_wiki}
    end
  end


  defp wiki_file(%{memex_directory: dir}) do
    "#{dir}/tidbit-db.json"
  end
end
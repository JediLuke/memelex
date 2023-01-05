defmodule Memelex.Utils.WikiManagement do


  @similarity_cutoff 0.72


  def new_tidbit(%{state: state, tidbit: t}) do
    title_already_exists? =
      state.wiki |> Enum.any?(fn tidbit -> tidbit.title == t.title end)

    if title_already_exists? do
      {:error, "this tidbit already exists"}
    else
      #TODO here we dont want to just use what's in memory, we want to re-read from disk!
      new_wiki = state.wiki ++ [t]
      wiki_file(state) |> Memelex.Utils.FileIO.write_maplist(new_wiki)
      {:ok, new_wiki}
    end
  end

   def save_tidbit(state, tidbit = %{uuid: this_uuid}) do
      # if it doesn't already exist, we need to create it
      case state.wiki |> Enum.find(& &1.uuid == this_uuid) do
         %{uuid: ^this_uuid} ->
            new_wiki = Enum.map(state.wiki, fn
                  %{uuid: ^this_uuid} ->
                     tidbit # replace with the incoming tidbit
                  any_other_tidbit ->
                     any_other_tidbit # don't change it...
               end)

            :ok = write_wiki_to_disk(state, new_wiki)
            {:ok, tidbit, new_wiki}
         nil ->
            new_wiki = state.wiki ++ [tidbit]
            :ok = write_wiki_to_disk(state, new_wiki)
            {:ok, tidbit, new_wiki}
      end
  end

  def add_tag(%{tag: tag, state: state, tidbit: %Memelex.TidBit{} = tidbit})
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
        wiki_file(state) |> Memelex.Utils.FileIO.write_maplist(new_wiki)

        {:ok, updated_tidbit, %{state|wiki: new_wiki}}
      end
  end


  def update_tidbit(%{state: state, tidbit: tidbit_to_update, updates: updates}) do

    # is_this_the_tidbit_were_looking_for? =
    #   fn(t) -> t.title == tidbit_to_update.title and t.uuid == tidbit_to_update.uuid end
    is_this_the_tidbit_were_looking_for? =
      fn(t) -> t.uuid == tidbit_to_update.uuid end
    
    tidbit =
      state.wiki |> Enum.find(:not_found, is_this_the_tidbit_were_looking_for?)

    if tidbit == :not_found do
      {:error, "Could not find a Tidbit with the title: #{inspect tidbit_to_update.title}"}
    else

      updated_tidbit =
        tidbit
        |> Map.merge(updates) #TODO need more validation on these updates! Could overwrite any field here right now!
        |> Map.merge(%{modified: DateTime.utc_now(), modifier: "JediLuke"}) #TODO get real values for these
      
      wiki_with_old_entry_removed =
        state.wiki |> Enum.reject(is_this_the_tidbit_were_looking_for?)
      
      new_wiki =
        wiki_with_old_entry_removed ++ [updated_tidbit]

      wiki_file(state) |> Memelex.Utils.FileIO.write_maplist(new_wiki)

      {:ok, updated_tidbit, new_wiki}
    end
  end

   def write_wiki_to_disk(state, wiki) do
      Memelex.Utils.FileIO.write(wiki_file(state), wiki)
   end

   defp wiki_file(%{memex_directory: dir}) do
      "#{dir}/tidbit-db.json"
   end
end
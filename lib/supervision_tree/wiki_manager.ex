defmodule Memex.Env.WikiManager do
  use GenServer
  require Logger
  alias Memex.Utils


  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  ##TODO this process should be backing up the wiki to disc (periodiclly?)

  def init(env) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, env, {:continue, :load_wiki_from_disk}}
  end



  def handle_continue(:load_wiki_from_disk, state) do

    if not File.exists?(wiki_file(state)) do
      Logger.warn "could not find a Wiki file for this environment. Creating one now..."
      {:ok, file} = File.open(wiki_file(state), [:write])
      IO.binwrite(file, [] |> Jason.encode!)
      File.close(file)
    end

    tidbit_list =
      wiki_file(state)
      |> Utils.FileIO.read_maplist()

    Logger.info "#{Enum.count(tidbit_list)} TidBits loaded from the Wiki file."
    {:noreply, state |> Map.merge(%{wiki: tidbit_list})}
  end

  def handle_call(:can_i_get_a_list_of_all_tidbits_plz, _from, state) do
    {:reply, {:ok, state.wiki}, state}
  end 

  def handle_call({:new_tidbit, %Memex.TidBit{} = t}, _from, state) do
    title_already_exists? =
      state.wiki |> Enum.any?(fn tidbit -> tidbit.title == t.title end)

    if title_already_exists? do
      {:reply, {:error, "this tidbit already exists"}, state}
    else
      new_wiki = state.wiki ++ [t]
      wiki_file(state) |> Utils.FileIO.write_maplist(new_wiki)
      {:reply, {:ok, t}, %{state|wiki: new_wiki}}
    end
  end

  def handle_call(:whats_the_current_memex_directory?, _from, state) do
    {:reply, {:ok, state.memex_directory}, state}
  end

  def handle_call(:whats_the_file_we_store_passwords_in_again?, _from, state) do
    {:reply, {:ok, "#{state.memex_directory}/passwords.txt"}, state}
  end

  def handle_call({:update_tidbit, tidbit, updates}, _from, state) do

    is_this_the_tidbit_were_looking_for? =
      fn(t) -> t.title == tidbit.title and t.uuid == tidbit.uuid end
    
    tidbit =
      state.wiki |> Enum.find(is_this_the_tidbit_were_looking_for?)

    if tidbit == [] do
      {:reply, {:error, "could not find a Tidbit with the title: #{inspect tidbit.title}"}, state}
    else

      updated_tidbit =
        tidbit
        |> Map.merge(updates) #TODO need more validation on these updates! Could overwrite any field here right now!
        |> Map.merge(%{modified: DateTime.utc_now(), modifier: "JediLuke"}) #TODO get real values for these
      
      wiki_with_old_entry_removed =
        state.wiki |> Enum.reject(is_this_the_tidbit_were_looking_for?)
      
      new_wiki =
        wiki_with_old_entry_removed ++ [updated_tidbit]

      wiki_file(state) |> Utils.FileIO.write_maplist(new_wiki)

      {:reply, {:ok, updated_tidbit}, %{state|wiki: new_wiki}}
    end
  end

  def handle_call({:add_tag, tidbit, tag}, _from, state) when is_bitstring(tag) do
  
    is_this_the_tidbit_were_looking_for? =
      fn(t) -> t.title == tidbit.title and t.uuid == tidbit.uuid end
    
    tidbit =
      state.wiki |> Enum.find(is_this_the_tidbit_were_looking_for?)

    if tidbit == [] do
      {:reply, {:error, "could not find a Tidbit with the title: #{inspect tidbit.title}"}, state}
    else

      updated_tidbit =
        tidbit
        |> Map.merge(%{tags: tidbit.tags ++ [tag]}) #TODO need more validation on these updates! Could overwrite any field here right now!
        |> Map.merge(%{modified: DateTime.utc_now(), modifier: "JediLuke"}) #TODO get real values for these
      
      wiki_with_old_entry_removed =
        state.wiki |> Enum.reject(is_this_the_tidbit_were_looking_for?)
      
      new_wiki =
        wiki_with_old_entry_removed ++ [updated_tidbit]

      wiki_file(state) |> Utils.FileIO.write_maplist(new_wiki)

      {:reply, {:ok, updated_tidbit}, %{state|wiki: new_wiki}}
    end
  end

  def handle_call({:find_tidbits, search_term}, _from, state) do
    similarity_cutoff = 0.72
    same_title? =
      # take in a %TidBit{} and test if it's title is a lot like what we're looking for
      fn t -> String.jaro_distance(search_term, t.title) >= similarity_cutoff end
    tidbits = state.wiki |> Enum.find(nil, same_title?)
    if tidbits == nil do
      {:reply, {:error, "could not find any TidBit with a title close to: `#{inspect search_term}`"}, state}
    else
      {:reply, {:ok, tidbits}, state}
    end
  end

  def handle_call({:delete_tidbit, %{uuid: uuid_to_be_deleted}}, _from, state) do
    new_wiki = state.wiki |> Enum.filter(& &1.uuid != uuid_to_be_deleted)
    wiki_file(state) |> Utils.FileIO.write_maplist(new_wiki)
    {:reply, :ok, %{state|wiki: new_wiki}}
  end



  defp wiki_file(%{memex_directory: dir}) do
    "#{dir}/tidbit-db.json"
  end

  #defp memex_filename(%{"name" => n}) do
  #  "#{n}.memex-env"
  #end


end
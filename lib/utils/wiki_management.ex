defmodule Memelex.Utils.WikiManagement do
  def new_tidbit(%{state: state, tidbit: %Memelex.TidBit{} = t}) do
    title_already_exists? = state.wiki |> Enum.any?(fn tidbit -> tidbit.title == t.title end)

    if title_already_exists? do
      {:error, "a TidBit with title: `#{t}` already exists"}
    else
      # TODO here we dont want to just use what's in memory, we want to re-read from disk!
      # If we keep doing this, whatever we've got in the GenServer wiki might end up over-writing what's on disk!
      new_wiki = state.wiki ++ [t]
      wiki_file(state) |> Memelex.Utils.FileIO.write_maplist(new_wiki)
      {:ok, new_wiki}
    end
  end

  # TODO don't ever save over another TidBit's UUID!!!
  # I WILL ADD THIS CHECK HERE
  def save_tidbit(state, tidbit = %Memelex.TidBit{uuid: this_uuid}) do
    # if it doesn't already exist, we need to create it
    case state.wiki |> Enum.find(&(&1.uuid == this_uuid)) do
      %{uuid: ^this_uuid} ->
        new_wiki =
          Enum.map(state.wiki, fn
            %{uuid: ^this_uuid} ->
              # replace with the incoming tidbit
              tidbit

            any_other_tidbit ->
              # don't change it...
              any_other_tidbit
          end)

        :ok = write_wiki_to_disk(state, new_wiki)
        # TODO here we should return the tidbit by re-fetching it off the disk,
        # because we might have changed it in the process of saving it, e.g.
        # things that get passed in with atom keys, get saved as string keys, and
        # since eventually once we do fetch everything back off disk they will
        # inevitebly be in string keys, we should return that here rather than
        # the form it came in with (atom keys) since we want it to be what actually got saved to disc

        fresh_wiki = read_wiki_from_disk(state)
        fresh_tidbit = fresh_wiki |> Enum.find(&(&1.uuid == this_uuid))

        {:ok, fresh_tidbit, fresh_wiki}

      nil ->
        new_wiki = state.wiki ++ [tidbit]
        :ok = write_wiki_to_disk(state, new_wiki)
        {:ok, tidbit, new_wiki}
    end
  end

  # def add_tag(%{tag: tag, state: state, tidbit: %Memelex.TidBit{} = tidbit})
  #   when is_bitstring(tag) do

  #     is_this_the_tidbit_were_looking_for? =
  #       fn(t) -> t.title == tidbit.title and t.uuid == tidbit.uuid end

  #     tidbit =
  #       state.wiki |> Enum.find(is_this_the_tidbit_were_looking_for?)

  #     if tidbit == [] do
  #       {:error, "Could not find a Tidbit with the title: #{inspect tidbit.title}"}
  #     else
  #       updated_tidbit =
  #         tidbit
  #         |> Map.merge(%{tags: tidbit.tags ++ [tag]}) #TODO need more validation on these updates! Could overwrite any field here right now!
  #         |> Map.merge(%{modified: DateTime.utc_now(), modifier: "JediLuke"}) #TODO get real values for these

  #       wiki_with_old_entry_removed =
  #         state.wiki |> Enum.reject(is_this_the_tidbit_were_looking_for?)

  #       new_wiki =
  #         wiki_with_old_entry_removed ++ [updated_tidbit]

  #       #TODO this seems to be working, but better to just overwrite the file again & refresh
  #       wiki_file(state) |> Memelex.Utils.FileIO.write_maplist(new_wiki)

  #       {:ok, updated_tidbit, %{state|wiki: new_wiki}}
  #     end
  # end

  # def update_tidbit(%{state: state, tidbit: tidbit_to_update, updates: updates}) do

  #   # is_this_the_tidbit_were_looking_for? =
  #   #   fn(t) -> t.title == tidbit_to_update.title and t.uuid == tidbit_to_update.uuid end
  #   is_this_the_tidbit_were_looking_for? =
  #     fn(t) -> t.uuid == tidbit_to_update.uuid end

  #   tidbit =
  #     state.wiki |> Enum.find(:not_found, is_this_the_tidbit_were_looking_for?)

  #   if tidbit == :not_found do
  #     {:error, "Could not find a Tidbit with the title: #{inspect tidbit_to_update.title}"}
  #   else

  #     updated_tidbit =
  #       tidbit
  #       |> Map.merge(updates) #TODO need more validation on these updates! Could overwrite any field here right now!
  #       |> Map.merge(%{modified: DateTime.utc_now(), modifier: "JediLuke"}) #TODO get real values for these

  #     wiki_with_old_entry_removed =
  #       state.wiki |> Enum.reject(is_this_the_tidbit_were_looking_for?)

  #     new_wiki =
  #       wiki_with_old_entry_removed ++ [updated_tidbit]

  #     wiki_file(state) |> Memelex.Utils.FileIO.write_maplist(new_wiki)

  #     {:ok, updated_tidbit, new_wiki}
  #   end
  # end

  def delete_tidbit(state, %Memelex.TidBit{uuid: uuid_to_be_deleted} = t) do
    # TODO remove from focussed_tidbit if that;s the one that got deleted (probably is)
    # I.e. make sure we're throwing an event somewhere in the correct place...
    new_wiki = state.wiki |> Enum.reject(&(&1.uuid == uuid_to_be_deleted))
    :ok = write_wiki_to_disk(state, new_wiki)

    # if they're an external tidbit e.g. a Journal entry or an Agent, delete that too!!
    if has_external_files_to_cleanup?(t) do
      cleanup_external_files(state, t)
    end

    {:ok, new_wiki}
  end

  # handles external files
  # moves things to trash before delete

  # def delete_tidbit_list(state, tidbit_list) do
  #   new_wiki = state.wiki |> Enum.reject(fn t -> t in tidbit_list end)
  #   :ok = write_wiki_to_disk(state, new_wiki)

  #   # if they're an external tidbit e.g. a Journal entry or an Agent, delete that too!!
  #   tidbit_list
  #   |> Enum.filter(&has_external_files_to_cleanup?(&1))
  #   |> Enum.each(fn t -> cleanup_external_files(state, t) end)

  #   {:ok, new_wiki}
  # end

  def has_external_files_to_cleanup?(%{
        data: %Memelex.Lib.Structs.MemexConcepts.V01.Agent{},
        tags: ["my_agents"]
      }) do
    true
  end

  def has_external_files_to_cleanup?(%{
        type: ["external", _filetype]
      }) do
    true
  end

  # here we are assuming if we havent defined a cleanup then it doesn't have any external files to clean up,
  # but it would be better to crash ehre and make us declare it one way or the other...
  def has_external_files_to_cleanup?(_tidbit) do
    IO.puts(
      "WARNING - has_external_files_to_cleanup? called on a tidbit and we dont have an explicit match whether or not there's exernal files to clean up!"
    )

    # false

    raise "has_external_files_to_cleanup? called on a tidbit and we dont have an explicit match whether or not there's exernal files to clean up!"
  end

  def cleanup_external_files(
        state,
        %{
          data: %Memelex.Lib.Structs.MemexConcepts.V01.Agent{},
          tags: ["my_agents"]
        } = tidbit
      ) do
    Memelex.Utils.AgentUtils.delete_agent_file(state, tidbit.data)
  end

  def cleanup_external_files(
        state,
        %{
          data: %{"file_path" => file_path},
          type: ["external", _filetype]
        } = tidbit
      ) do
    case File.rm(file_path) do
      :ok ->
        # Logger.info("Deleted external file: #{file_path}")
        :ok

      {:error, :enoent} ->
        # Logger.info("Could not find external file: #{file_path}")
        # Logger.warn(": #{file_path}")
        IO.puts(
          "Could not find (during cleanup!) an external file. Could not delete external file: #{file_path}"
        )

        :error
    end
  end

  def write_wiki_to_disk(state, wiki) do
    Memelex.Utils.FileIO.write(wiki_file(state), wiki)
  end

  def read_wiki_from_disk(state) do
    Memelex.Utils.FileIO.read_maplist(wiki_file(state))
  end

  def wiki_file(%{memex_directory: dir}) do
    "#{dir}/tidbit-db.json"
  end
end

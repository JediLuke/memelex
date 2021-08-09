defmodule Memex.Env.WikiManager do
  use GenServer
  require Logger
  alias Memex.Utils


  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

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
    results = Memex.Utils.WikiManagement.new_tidbit(%{tidbit: t, state: state})
    case results do
      {:ok, new_wiki} ->
        {:reply, {:ok, t}, %{state|wiki: new_wiki}}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:whats_the_current_memex_directory?, _from, state) do
    {:reply, {:ok, state.memex_directory}, state}
  end

  def handle_call(:whats_the_current_backups_directory?, _from, state) do
    {:reply, {:ok, state.backups_directory}, state}
  end

  def handle_call(:whats_the_file_we_store_passwords_in_again?, _from, state) do
    {:reply, {:ok, "#{state.memex_directory}/passwords.txt"}, state}
  end

  def handle_call({:update_tidbit, tidbit, updates}, _from, state) do
    results = Memex.Utils.WikiManagement.update_tidbit(%{state: state, tidbit: tidbit, updates: updates})
    case results do
      {:ok, updated_tidbit, new_wiki} ->
        {:reply, {:ok, updated_tidbit}, %{state|wiki: new_wiki}}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:add_tag, tidbit, tag}, _from, state) when is_bitstring(tag) do
    {:ok, updated_tidbit, new_wiki} =
       Memex.Utils.WikiManagement.add_tag(%{tag: tag, state: state, tidbit: tidbit})
    {:reply, {:ok, updated_tidbit}, %{state|wiki: new_wiki}}
  end

  def handle_call({:find_tidbits, search_term}, _from, state) do
    results = Memex.Utils.WikiManagement.find(%{state: state, search_term: search_term})
    {:reply, results, state}
  end

  def handle_call({:delete_tidbit, %{uuid: uuid_to_be_deleted}}, _from, state) do
    raise "cant delete until you stop writing from memory to disk! re-read, update - then refresh"
    #new_wiki = state.wiki |> Enum.filter(& &1.uuid != uuid_to_be_deleted)
    #wiki_file(state) |> Utils.FileIO.write_maplist(new_wiki)
    #{:reply, :ok, %{state|wiki: new_wiki}}
  end


  defp wiki_file(%{memex_directory: dir}) do
    "#{dir}/tidbit-db.json"
  end
end
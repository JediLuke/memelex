defmodule Memelex.WikiServer do
  @moduledoc """
  A GenServer which keeps all TidBits in memory, so
  we don't need to re-read all TidBits in from disk
  every time we want to query the Wiki database.

  W.I.K.I. = What I Know Is...
  """
  use GenServer
  require Logger
  alias Memelex.Utils
  alias Memelex.Utils.WikiManagement

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  def init(env) do
    Logger.info("#{__MODULE__} initializing...")
    {:ok, env, {:continue, :load_wiki_from_disk}}
  end

  def handle_continue(:load_wiki_from_disk, state) do
    {:ok, tidbit_list} = do_load_wiki(state)

    Logger.info("#{Enum.count(tidbit_list)} TidBits loaded from the Wiki file.")
    {:noreply, state |> Map.merge(%{wiki: tidbit_list})}
  end

  def handle_call(:list_all_tidbits, _from, state) do
    {:reply, {:ok, state.wiki}, state}
  end

  def handle_call({:fetch, %{tidbit_uuid: t_uuid}}, _from, state) do
    full_tidbit = Enum.find(state.wiki, &(&1.uuid == t_uuid))
    {:reply, {:ok, full_tidbit}, state}
  end

  def handle_call({:fetch, %{uuid: t_uuid}}, _from, state) do
    full_tidbit = Enum.find(state.wiki, &(&1.uuid == t_uuid))
    {:reply, {:ok, full_tidbit}, state}
  end

  def handle_call({:new_tidbit, %Memelex.TidBit{} = t}, _from, state) do
    WikiManagement.new_tidbit(%{tidbit: t, state: state})
    |> case do
      {:ok, new_wiki} ->
        {:reply, {:ok, t}, %{state | wiki: new_wiki}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:deactivate, _from, memex_env) do
    Logger.info("deactivating...")
    # TODO update Application config, shjut down the Wiki, etc...
    {:stop, :normal, memex_env}
  end

  # # fetches exactly 1 TidBit
  # def handle_call({:find_tidbit, params}, _from, state) do
  #   Utils.Search.one_tidbit(state.wiki, params)
  #   |> case do
  #     {:ok, %Memelex.TidBit{} = result} ->
  #       {:reply, {:ok, result}, state}
  #     {:ok, results} when is_list(results) and length(results) >= 1 ->
  #       {:reply, {:error, "more than 1 TidBit found for this query"}, state}
  #     otherwise ->
  #       IO.inspect otherwise
  #       {:reply, {:error, "unable to find TidBit for this search term"}, state}
  #   end
  # end

  # returns multiple tidbits, in a list (no tuple)
  def handle_call({:list_tidbits, params}, _from, state) do
    Utils.Search.tidbits(state.wiki, params)
    |> case do
      {:ok, results} ->
        {:reply, {:ok, results}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:save_tidbit, %Memelex.TidBit{} = tidbit}, _from, state) do
    {:ok, saved_tidbit, new_wiki} = WikiManagement.save_tidbit(state, tidbit)

    {:reply, {:ok, saved_tidbit}, %{state | wiki: new_wiki}}
  end

  def handle_call({:delete_tidbit, tidbit}, _from, state) do
    {:ok, new_wiki} = WikiManagement.delete_tidbit(state, tidbit)

    {:reply, :deleted, %{state | wiki: new_wiki}}
  end

  def handle_call({:update_tidbit, tidbit, %{add_tag: tag}}, _from, state) do
    {:ok, updated_tidbit, new_wiki} =
      WikiManagement.add_tag(%{tag: tag, state: state, tidbit: tidbit})

    {:reply, {:ok, updated_tidbit}, %{state | wiki: new_wiki}}
  end

  def handle_call({:update_tidbit, tidbit, updates}, _from, state) do
    WikiManagement.update_tidbit(%{state: state, tidbit: tidbit, updates: updates})
    |> case do
      {:ok, %Memelex.TidBit{} = updated_tidbit, new_wiki} ->
        {:reply, {:ok, updated_tidbit}, %{state | wiki: new_wiki}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:whats_the_current_memex_directory?, _from, state) do
    {:reply, {:ok, state.memex_directory}, state}
  end

  def handle_call(:whats_the_current_backups_directory?, _from, %{backups_directory: dir} = state) do
    {:reply, {:ok, dir}, state}
  end

  def handle_call(:whats_the_current_backups_directory?, _from, state) do
    {:reply, {:error, "No Backups directory found."}, state}
  end

  def handle_call(:whats_the_file_we_store_passwords_in_again?, _from, state) do
    {:reply, {:ok, "#{state.memex_directory}/passwords.txt"}, state}
  end

  def do_load_wiki(state) do
    check_wiki_file_exists_and_if_it_doesnt_exist_create_it(state)

    tidbit_list =
      wiki_file(state)
      |> Utils.FileIO.read_maplist()

    {:ok, tidbit_list}
  end

  def check_wiki_file_exists_and_if_it_doesnt_exist_create_it(state) do
    # make new wiki file if one doesn't exist
    if not File.exists?(wiki_file(state)) do
      Logger.warn("Could not find a Wiki file for this environment. Creating one now...")
      # TODO use a Utils function here, don't werite directly to a file
      {:ok, file} = File.open(wiki_file(state), [:write])
      IO.binwrite(file, [] |> Jason.encode!())
      File.close(file)
    end
  end

  defp wiki_file(%{memex_directory: dir}) do
    "#{dir}/tidbit-db.json"
  end
end

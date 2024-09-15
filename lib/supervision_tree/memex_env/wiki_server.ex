defmodule Memelex.WikiServer do
  @moduledoc """
  A GenServer which keeps all TidBits in memory, so
  we don't need to re-read all TidBits in from disk
  every time we want to query the Wiki database.

  W.I.K.I. = What I Know Is...
  """
  use GenServer
  require Logger
  alias Memelex.TidBit
  alias Memelex.Utils.{FileIO, WikiSearch, WikiManagement}

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  def init(env) do
    Logger.debug("#{__MODULE__} initializing... #{inspect(env)}")
    {:ok, env, {:continue, :load_wiki_from_disk}}
  end

  def refresh do
    GenServer.cast(__MODULE__, :refresh)
  end

  def handle_continue(:load_wiki_from_disk, state) do
    {:ok, tidbit_list} = do_load_wiki(state)

    Logger.info("#{Enum.count(tidbit_list)} TidBits loaded from the Wiki file.")
    {:noreply, state |> Map.merge(%{wiki: tidbit_list})}
  end

  def handle_call({:new_tidbit, %TidBit{} = t}, _from, state) do
    WikiManagement.new_tidbit(%{tidbit: t, state: state})
    |> case do
      {:ok, new_wiki} ->
        {:reply, {:ok, t}, %{state | wiki: new_wiki}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:list_all, _from, state) do
    {:reply, {:ok, state.wiki}, state}
  end

  def handle_call(:list_all_tidbits, _from, state) do
    IO.puts("DEPRECATE MEEEEE")
    {:reply, {:ok, state.wiki}, state}
  end

  def handle_call({:get, %{uuid: t_uuid}}, _from, state) when is_binary(t_uuid) do
    case Enum.find(state.wiki, &(&1.uuid == t_uuid)) do
      nil ->
        {:reply, {:error, "No TidBit found with UUID #{t_uuid}"}, state}

      %TidBit{} = t ->
        {:reply, {:ok, t}, state}
    end
  end

  def handle_call({:find_one, query}, _from, state) do
    result = WikiSearch.find_one(state.wiki, query)
    {:reply, result, state}
  end

  # returns multiple tidbits, in a list (no tuple)
  def handle_call({:find_all, query}, _from, state) do
    results = WikiSearch.find_all(state.wiki, query)
    {:reply, {:ok, results}, state}
  end

  def handle_call({:find_any, query}, _from, state) do
    results = WikiSearch.find_any(state.wiki, query)
    {:reply, {:ok, results}, state}
  end

  # def handle_call({:list_tidbits, params}, from, state) do
  #   IO.puts("CEPRECATE MEEEE")
  #   handle_call({:find_all, params}, from, state)
  # end

  # def handle_call({:fetch, %{tidbit_uuid: t_uuid}}, _from, state) do
  #   full_tidbit = Enum.find(state.wiki, &(&1.uuid == t_uuid))
  #   {:reply, {:ok, full_tidbit}, state}
  # end

  # def handle_call({:custom_settings, %{tidbit_uuid: t_uuid}}, _from, state) do
  #   full_tidbit = Enum.find(state.wiki, &(&1.uuid == t_uuid))
  #   {:reply, {:ok, full_tidbit}, state}
  # end

  # def handle_call({:fetch, %{uuid: t_uuid}}, _from, state) do
  #   full_tidbit = Enum.find(state.wiki, &(&1.uuid == t_uuid))
  #   {:reply, {:ok, full_tidbit}, state}
  # end

  # def handle_call({:delete, tidbit_list}, _from, state) when is_list(tidbit_list) do
  #   {:ok, new_wiki, deleted_items} = WikiManagement.delete_tidbit_list(state, tidbit_list)
  #   {:reply, {:ok, %{"deleted_items" => deleted_items}}, %{state | wiki: new_wiki}}
  # end

  def handle_call(:deactivate, _from, memex_env) do
    Logger.info("deactivating...")
    # TODO update Application config, shjut down the Wiki, etc...
    {:stop, :normal, memex_env}
  end

  # # fetches exactly 1 TidBit
  # def handle_call({:find_tidbit, params}, _from, state) do
  #   Utils.Search.one_tidbit(state.wiki, params)
  #   |> case do
  #     {:ok, %TidBit{} = result} ->
  #       {:reply, {:ok, result}, state}
  #     {:ok, results} when is_list(results) and length(results) >= 1 ->
  #       {:reply, {:error, "more than 1 TidBit found for this query"}, state}
  #     otherwise ->
  #       IO.inspect otherwise
  #       {:reply, {:error, "unable to find TidBit for this search term"}, state}
  #   end
  # end

  def handle_call({:save_tidbit, %TidBit{} = tidbit}, _from, state) do
    {:ok, saved_tidbit, new_wiki} = save_tidbit_fire_event(state, tidbit)
    {:reply, {:ok, saved_tidbit}, %{state | wiki: new_wiki}}
  end

  def handle_call({:modify_tidbit, %TidBit{} = tidbit, updates}, _from, state) do
    # TODO this should at the least be done in Wormhole
    {:ok, saved_tidbit, new_wiki} =
      tidbit
      |> TidBit.modify(updates)
      |> save_tidbit_fire_event(state)

    {:reply, {:ok, saved_tidbit}, %{state | wiki: new_wiki}}
  end

  def handle_call({:update_tidbit, %TidBit{} = tidbit, updates}, from, state) do
    IO.puts("UPDATE??? CALL MODIFY!!!")
    handle_call({:modify_tidbit, %TidBit{} = tidbit, updates}, from, state)
  end

  def handle_call({:delete, tidbit}, _from, state) do
    {:ok, new_wiki} = WikiManagement.delete_tidbit(state, tidbit)
    {:reply, :ok, %{state | wiki: new_wiki}}
  end

  # def handle_call({:delete_tidbit, tidbit}, _from, state) do
  #   {:ok, new_wiki} = WikiManagement.delete_tidbit(state, tidbit)
  #   {:reply, :ok, %{state | wiki: new_wiki}}
  # end

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

  def handle_cast(:refresh, state) do
    Logger.info("#{__MODULE__} refreshing...")

    {:ok, tidbit_list} = do_load_wiki(state)

    Logger.info("#{Enum.count(tidbit_list)} TidBits loaded from the Wiki file.")
    {:noreply, state |> Map.merge(%{wiki: tidbit_list})}
  end

  def do_load_wiki(state) do
    create_new_wiki_file_if_one_doesnt_exist(state)

    tidbit_list =
      wiki_file(state)
      |> FileIO.read_maplist()

    {:ok, tidbit_list}
  end

  def create_new_wiki_file_if_one_doesnt_exist(state) do
    # make new wiki file if one doesn't exist
    if not File.exists?(wiki_file(state)) do
      Logger.warn(
        "Could not find a Wiki file for this environment. Creating one now... #{inspect(wiki_file(state))}"
      )

      # TODO use a Utils function here, don't werite directly to a file
      {:ok, file} = File.open(wiki_file(state), [:write])
      IO.binwrite(file, [] |> Jason.encode!())
      File.close(file)
    end
  end

  # NOTE - ok so in the past I might have created this `declare` which would
  # fire an event & also return a value... not really consistent with an "event driven architecture" :P
  # now I'm doing the updatesd inline, I think we still want to fire an event so that UIs
  # etc can get updated, but we don't need to worry about declare...
  # TODO use declare here somehow, so the actual TidBit gets returned...

  # Memelex.Fluxus.action({
  #   Memelex.Fluxus.Reducers.TidbitReducer,
  #   {:update, tidbit, updates}
  # })

  defp save_tidbit_fire_event(%TidBit{} = t, state) do
    # TODO reverse order of these args... sve_tidbit(t, state) !!
    {:ok, saved_tidbit, new_wiki} = WikiManagement.save_tidbit(state, t)
    Memelex.Fluxus.event({:tidbit_saved, saved_tidbit})
    {:ok, saved_tidbit, new_wiki}
  end

  defp save_tidbit_fire_event(state, tidbit) do
    {:ok, saved_tidbit, new_wiki} = WikiManagement.save_tidbit(state, tidbit)
    Memelex.Fluxus.event({:tidbit_saved, saved_tidbit})
    {:ok, saved_tidbit, new_wiki}
  end

  defp wiki_file(%{memex_directory: dir}) do
    "#{dir}/tidbit-db.json"
  end
end

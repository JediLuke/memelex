defmodule Memex.Env.WikiManager do
  use GenServer
  require Logger
  alias Memex.Utils


  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: Memex.Env.WikiManager)
  end


  @impl GenServer
  def init(env) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, env, {:continue, :load_wiki_from_disk}}
  end


  @impl GenServer
  def handle_continue(:load_wiki_from_disk, state) do
    tidbit_list = wiki_file(state) |> Utils.FileIO.read_maplist()
    Logger.info "#{Enum.count(tidbit_list)} TidBits loaded from the Wiki file."
    {:noreply, state |> Map.merge(%{wiki: tidbit_list})}
  end

  @impl GenServer
  def handle_cast({:add_tidbit, t}, state) do
    new_wiki = state.wiki |> Enum.into([t])
    wiki_file(state) |> Utils.FileIO.write_maplist(new_wiki)
    {:noreply, %{state|wiki: new_wiki}}
  end

  defp wiki_file(%{"memex_directory" => dir}) do
    "#{dir}/tidbit-db.json"
  end
end
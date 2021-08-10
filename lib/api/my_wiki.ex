defmodule Memex.My.Wiki do
  @moduledoc """
  W.I.K.I. = What I Know is...
  """
  alias Memex.Env.WikiManager
  alias Memex.Utils.TidBits.ConstructorLogic, as: TidBitUtils

  def new(params) do
    params
    |> TidBitUtils.sanitize_conveniences()
    |> Memex.TidBit.construct()
    |> Memex.My.Wiki.new_tidbit()
  end

  def new_tidbit(%Memex.TidBit{} = t) do
    WikiManager |> GenServer.call({:new_tidbit, t})
  end

  def new_tidbit(params) do
    params
    |> TidBitUtils.sanitize_conveniences()
    |> Memex.TidBit.construct()
    |> new_tidbit()
  end

  def new_linked_tidbit(%{} = tidbit, params) do
    {:ok, new_tidbit} = 
      params
      |> Memex.TidBit.construct()
      |> new_tidbit()

    link(tidbit, new_tidbit)

    {:ok, new_tidbit}
  end

  def home do
    raise "this returns all the Tidbits on the home carousel"
  end

  def feed do
    raise "this is the auto-generated / pre-compiled / whatever, recommended tidBit feed"
  end

  @doc ~s(Return a list containing every single TidBit.)
  def list do
    {:ok, tidbits} = WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)
    tidbits
  end

  def list(:external) do
    list() |> Enum.filter(& &1.type |> Enum.member?("external"))
  end

  @doc """
  Used to get a unique list of one of the Wiki's sub fields,
  e.g. list(:tags) or list(:type)
  """ 
  def list(wiki_field) when is_atom(wiki_field) do
    list() |> Enum.map(& Map.get(&1, wiki_field)) |> List.flatten() |> Enum.uniq()
  end

  def list(map) when is_map(map) do
    keyword_params = Memex.Utils.MiscElixir.convert_map_to_keyword_list(map)
    list(keyword_params)
  end

  def list(params) when is_list(params) do
    {:ok, tidbits} = WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)
    tidbits |> Enum.filter(&Memex.Utils.Search.typed_and_tagged?(&1, params))
  end

  def find(search_term) do
    {:ok, tidbit} = WikiManager |> GenServer.call({:find_tidbit, search_term})
    tidbit
  end

  def find(search_term, opts) when is_list(opts) do
    {:ok, tidbit} = WikiManager |> GenServer.call({:find_tidbit, search_term, opts})
    tidbit
  end

  def open(params) do
    find(params) |> Memex.Utils.ToolBag.open_external_textfile()
  end

  @doc ~s(Update a Tidbit.)
  def update(tidbit_being_updated, updates) do
    WikiManager |> GenServer.call({:update_tidbit, tidbit_being_updated, updates})
  end

  def tag(tidbit, tag) do
    add_tag(tidbit, tag)
  end

  def add_tag(tidbit, tag) when is_bitstring(tag) do
    update(tidbit, %{add_tag: tag})
  end

  @doc ~s(Create a link between two TidBits.)
  def link(base_node, link_node) do

    # links/backlinks are just saved lists of references to other TidBits
    # so first, we simply compute what those new lists will be
    new_base_node_links = base_node.links ++ [link_node |> Memex.TidBit.construct_reference()]
    new_link_node_bases = link_node.backlinks ++ [base_node |> Memex.TidBit.construct_reference()]

    # then we update each seperately - with the correct list of course!!
    WikiManager |> GenServer.call({:update_tidbit, base_node, %{links: new_base_node_links}})
    WikiManager |> GenServer.call({:update_tidbit, link_node, %{backlinks: new_link_node_bases}})

    :ok
  end

  def delete(tidbit) do
    WikiManager |> GenServer.call({:delete_tidbit, tidbit})
  end
end
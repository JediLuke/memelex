defmodule Memex.My.Wiki do
  @moduledoc """
  W.I.K.I. = What I Know is...
  """
  alias Memex.Env.WikiManager

  def new_tidbit(%Memex.TidBit{} = t) do
    WikiManager |> GenServer.call({:new_tidbit, t})
  end

  def new_tidbit(params) do
    params
    |> Memex.TidBit.construct()
    |> new_tidbit()
  end

  def new_text_snippet(params) do
    uuid = UUID.uuid4()

    new_snippet_filepath =
      Memex.Utils.ToolBag.memex_directory()
      |> Path.join("/text_snippets")
      |> Path.join("/#{uuid}.txt")

    snippet =
      case params[:data] do
        t when is_bitstring(t) -> t
        _otherwise -> ""
      end

    if File.exists?(new_snippet_filepath) do
        raise "we're trying to overwrite an existing text-snippet!!"
    else
        Memex.Utils.FileIO.write(new_snippet_filepath, snippet)
    end

    {"", 0} = System.cmd("gedit", [new_snippet_filepath])

    params
    |> Map.merge(%{uuid: uuid, type: :text_snippet, data: %{filename: "#{uuid}.txt"}})
    |> Memex.TidBit.construct()
    |> new_tidbit()
  end

  def open_text_snippet(%{type: ["text_snippet"], data: %{"filename" => filename}}) do
    snippet = Memex.Utils.ToolBag.text_snippets_directory() <> "/#{filename}"
    {"", 0} = System.cmd("gedit", [snippet])
    :ok
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

  def list(:types) do
    list() |> Enum.map(& &1.type) |> Enum.uniq()
  end

  def list(:tags) do
    list() |> Enum.map(& &1.tags) |> List.flatten() |> Enum.uniq()
  end

  def find(%{uuid: uuid}) do
    {:ok, tidbit} = WikiManager |> GenServer.call({:find_tidbits, {:uuid, uuid}})
    tidbit
  end

  def find(tagged: tag) when is_binary(tag) do
    {:ok, tidbit} = WikiManager |> GenServer.call({:find_tidbits, {:tagged, tag}})
    tidbit
  end

  def find(search_term) when is_binary(search_term) do
    {:ok, tidbit} = WikiManager |> GenServer.call({:find_tidbits, search_term})
    tidbit
  end

  #TODO
  def find(search_term, opts) when is_binary(search_term) and is_list(opts) do
    raise "this one isnt working yet"
    {:ok, tidbit} = WikiManager |> GenServer.call({:find_tidbits, search_term, opts})
    tidbit
  end

  @doc ~s(Update a Tidbit.)
  def update(tidbit_being_updated, updates) do
    WikiManager |> GenServer.call({:update_tidbit, tidbit_being_updated, updates})
  end

  def add_tag(tidbit, tag) when is_bitstring(tag) do
    WikiManager |> GenServer.call({:add_tag, tidbit, tag})
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
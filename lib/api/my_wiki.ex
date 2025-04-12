defmodule Memelex.My.Wiki do
  @moduledoc """
  W.I.K.I. = What I Know is...
  """
  alias Memelex.WikiServer
  alias Memelex.Utils.TidBits.ConstructorLogic, as: TidBitUtils
  require Logger

  # def new(param_one, param_two) do
  #   Logger.warning "Here, we should be enabling things like:

  #       Memelex.new 'Hippy string title', tags: 'blah', 'nlajh'

  #   But right now, who knows!"
  #   params
  #   # |> TidBitUtils.sanitize_conveniences()
  #   |> Memelex.TidBit.new()
  #   |> __MODULE__.new_tidbit()
  # end

  # TODO there's a bug making new TidBits
  #     they get saved with a ~U[2021-11-09 02:45:44.567300Z] as "created",
  #     it needs to be a saved string timestamp
  # def new_tidbit(%Memelex.TidBit{} = t) do
  #   Memelex.WikiServer |> GenServer.call({:new_tidbit, t})
  # end

  def new do
    new(%{})
  end

  def new(name) when is_binary(name) do
    new(%{title: name})
  end

  def new(%Memelex.TidBit{} = new_tidbit) do
    {:ok, saved_tidbit} = save(new_tidbit)
    saved_tidbit
  end

  def new(args) when is_map(args) do
    args
    # |> TidBiztUtils.sanitize_conveniences()
    |> Memelex.TidBit.new()
    |> new()
  end

  def add(args) do
    new(args)
  end

  def find(args) do
    find_all(args)
  end

  @doc ~s(Return a list containing every single TidBit.)
  def all do
    {:ok, tidbits} = GenServer.call(WikiServer, :list_all)
    tidbits
  end

  def all(query) do
    {:ok, tidbits} = GenServer.call(WikiServer, {:find_all, query})
    tidbits
  end

  def any(query) do
    {:ok, tidbits} = GenServer.call(WikiServer, {:find_any, query})
    tidbits
  end

  def random do
    # fetch a random TidBit
    all() |> Enum.random()
  end

  # returns exactly one TidBit
  def get(uuid) when is_binary(uuid) do
    get(%{uuid: uuid})
  end

  # `is_binary` is a terrible name, is_binary should be is_bitstring and is_bitsting should be just `is_bitstream` for what should be `div8_
  # maybe `is_utf8_string` or `is_octet_bitstring`
  def get(%{uuid: uuid} = args) when is_binary(uuid) do
    GenServer.call(WikiServer, {:get, args})
  end

  def get!(uuid) when is_binary(uuid) do
    get!(%{uuid: uuid})
  end

  def get!(args) do
    case get(args) do
      {:ok, %Memelex.TidBit{} = tidbit} ->
        tidbit

      {:error, reason} ->
        raise "Could not find a TidBit with args: #{inspect(args)}.\n\n#{inspect(reason)}}"
    end
  end

  # why not lol
  # def edit(tidbit, updates) do
  #   update(tidbit, updates)
  # end

  # use modify over update, what is an update? it's a modification
  def modify(%Memelex.TidBit{} = tidbit, updates) do
    GenServer.call(WikiServer, {:modify_tidbit, tidbit, updates})
  end

  @doc """
  Perform an edit on an existing TidBit. This means update content,
  change the title, etc.
  """
  def update(%Memelex.TidBit{} = tidbit, updates) do
    GenServer.call(WikiServer, {:modify_tidbit, tidbit, updates})
  end

  # def close(tidbit) do
  # todo here we would throw an event *& the memex/flamelex app would respond to it...
  # end

  # def new_linked_tidbit(%{} = tidbit, params) do
  #   {:ok, new_tidbit} =
  #     params
  #     |> Memelex.TidBit.new()
  #     |> new_tidbit()

  #   link(tidbit, new_tidbit)

  #   {:ok, new_tidbit}
  # end

  # def home do
  #   # TODO we can throw an event here & make it a convenience function - but we're not implementing this...
  #   raise "this returns all the Tidbits on the home carousel"
  # end

  def save(%Memelex.TidBit{} = t) do
    GenServer.call(WikiServer, {:save_tidbit, t})
  end

  # returns a unique list of every tag in the wiki
  def all_tags do
    all()
    |> Enum.reduce(_tags_list = [], fn t, acc_tags ->
      acc_tags ++ t.tags
    end)
    |> Enum.uniq()
  end

  def find_one(query) do
    GenServer.call(WikiServer, {:find_one, query})
  end

  def find_one!(query) do
    case find_one(query) do
      # {:ok, %Memelex.TidBit{} = tidbit} ->
      {:ok, []} ->
        raise "Could not find a TidBit with query: #{inspect(query)}.}"

      {:ok, [%Memelex.TidBit{} = tidbit]} ->
        tidbit
      # {:error, reason} ->
    end
  end

  def find_all(query) do
    {:ok, wiki} = GenServer.call(WikiServer, {:find_all, query})
    wiki
  end

  # this is just a shorthand I made because quite often all I want is the titles
  def find_all(query, key_opt) when key_opt in [:t, :title] do
    find_all(query) |> Enum.map(& &1.title)
  end

  def tag(%Memelex.TidBit{} = t, new_tag) when is_binary(new_tag) do
    tag(t, [new_tag])
  end

  def tag(%Memelex.TidBit{} = t, new_tags) when is_list(new_tags) do
    # GenServer.call(WikiServer, {:edit_tidbit, t, %oupdate({add_tags: new_tags}})
    update(t, %{add_tags: new_tags})
  end

  # record some history about a TidBit - adds a timestamped log to the TidBit's history
  def rec_history(%Memelex.TidBit{} = t, log) when is_binary(log) do
    update(t, %{append_to_history: log})
  end

  #   # add_tag(tidbit, tag)

  #   # TODO should we put this tidbit into edit mode, considering we aren't saving it???

  #   # we can't call edit & get back a tidbit, so we cant pass this tidbit into save
  #   # we can't call save after the fact, because then we will pass in the old tidbit & it wont save
  #   # the solution is to force it to save the tidbit in RadixState memory by giving it a specific uuid

  #   # edit(tidbit, %{add_tags: new_tags})
  #   # edit(tidbit, )
  #   # save(%{tidbit_uuid: tidbit.uuid})
  #   # Memelex.Fluxus.action({TidbitReducer, {:update_tidbit, t, {:add_tags, new_tags}}})
  # end

  def open(%Memelex.TidBit{} = t) do
    # this is inside Memelex, and `open` only has any effect in GUI mode, so fire an event
    # even if we want Memelex to open an external GUI e.g. gedit, then the internal event
    # handler inside Memelex (which is disabled when running in GUI mode aka as a part of Flamelex) will handle it
    Memelex.Fluxus.event({:open_tidbit, t})
  end

  def open(%{"uuid" => t_uuid}) do
    Memelex.Fluxus.event({:open_tidbit, get!(t_uuid)})
  end

  @doc ~s(Create a link between two TidBits.)
  def link(base_node, link_node) do
    # links/backlinks are just saved lists of references to other TidBits
    # so first, we simply compute what those new lists will be
    new_base_node_links = base_node.links ++ [link_node |> Memelex.TidBit.construct_reference()]

    new_link_node_bases =
      link_node.backlinks ++ [base_node |> Memelex.TidBit.construct_reference()]

    # then we update each seperately - with the correct list of course!!
    Memelex.WikiServer
    |> GenServer.call({:update_tidbit, base_node, %{links: new_base_node_links}})

    Memelex.WikiServer
    |> GenServer.call({:update_tidbit, link_node, %{backlinks: new_link_node_bases}})

    :ok
  end

  # @spec delete(any) :: any
  def delete([]), do: :ok

  def delete([tidbit | rest]) do
    # TODO maybe do this as a bulk operation
    GenServer.call(Memelex.WikiServer, {:delete, tidbit})
    delete(rest)
  end

  def delete(query) do
    GenServer.call(WikiServer, {:delete, query})
  end
end

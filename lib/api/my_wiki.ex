defmodule Memelex.My.Wiki do
  @moduledoc """
  W.I.K.I. = What I Know is...
  """
  alias Memelex.WikiServer
  alias Memelex.Utils.TidBits.ConstructorLogic, as: TidBitUtils
  require Logger

  alias Memelex.Fluxus.Structs.RadixState
  alias Memelex.Fluxus.Reducers.TidbitReducer

  def focussed do
    # fetches the active TidBit from the GUI
    #NOTE this should raise in non-GUI mode
    focussed_uuid = Memelex.Fluxus.RadixStore.get().story_river.focussed_tidbit
    find!(%{tidbit_uuid: focussed_uuid})
  end

  # same as new, but opens in the GUI mode `:edit`
  # def create() do
    
  # end

  # This is similar to new except we save the TidBit right away,
  # rather than merely opening it in Edit mode. This is more applicable
  # for use via API.s e.g. `My.Bills.new/1` wants to make & save a
  # new TidBit, not open one in the open tidbits story river
  def add(%Memelex.TidBit{} = new_tidbit) do
    Memelex.Fluxus.action({TidbitReducer, {:add_tidbit, new_tidbit}})
    new_tidbit
  end

  def add(args) when is_map(args) do
    %Memelex.TidBit{} = t =
      # |> TidBiztUtils.sanitize_conveniences()
      Memelex.TidBit.construct(args)

    add(t)
  end

  def new do
    new(%{title: ""})
  end

  def new(%Memelex.TidBit{} = new_tidbit) do
    Memelex.Fluxus.action({TidbitReducer, {:new_tidbit, new_tidbit}})
    new_tidbit
  end

  def new(args) when is_map(args) do
    # %Memelex.TidBit{} = new_tidbit = params
    # |> Memelex.TidBit.construct()
    
    %Memelex.TidBit{} = t =
      # |> TidBiztUtils.sanitize_conveniences()
      Memelex.TidBit.construct(args)

    # Memelex.Fluxus.action({TidbitReducer, {:new_tidbit, new_tidbit}})

    # new_tidbit
    new(t)
  end

  # def new(params, save_to_disk_on_creation?: true) do
  #   %{uuid: t_uuid} = new(params)
  #   save(%{tidbit_uuid: t_uuid})
  # end

  #TODO add check for when running in gui mode or not
  def open(%Memelex.TidBit{} = t) do
    Memelex.Fluxus.action({TidbitReducer, {:open_tidbit, t}})
  end

  @doc """
  Perform an edit on an existing TidBit. This means update content,
  change the title, etc.

  `modification` is a generic field which gets passed through.

  This update happens via an action being processed by the Fluxus system,
  so we don't need to concern ourselves with serializing operations here -
  that comes when we want to save to disk, we will wrap reads & saves in a process.
  """
  def edit(%Memelex.TidBit{} = t, modification) do
    Memelex.Fluxus.action({TidbitReducer, {:edit_tidbit, t, modification}})
  end


  # def update(%Memelex.TidBit{} = tidbit, updates) do
  #   #TODO this might actually be a good idea, serialize this operation inside a GenServer??
  #   # Memelex.WikiServer |> GenServer.call({:update_tidbit, tidbit_being_updated, updates})

  #   #TODO use declare here somehow, so the actual TidBit gets returned...

  #   Memelex.Fluxus.action({
  #     Memelex.Fluxus.Reducers.TidbitReducer,
  #     {:update, tidbit, updates}
  #   })
  # end


  def close(tidbit) do
    # radix_state = Memelex.Fluxus.RadixStore.get()
    IO.puts "HER HER NEXT WE NEED TO CLOSE TIDBITS"
  end

  # def new(param_one, param_two) do
  #   Logger.warn "Here, we should be enabling things like:

  #       Memelex.new 'Hippy string title', tags: 'blah', 'nlajh'
    
  #   But right now, who knows!"
  #   params
  #   # |> TidBitUtils.sanitize_conveniences()
  #   |> Memelex.TidBit.construct()
  #   |> __MODULE__.new_tidbit()
  # end

  #TODO there's a bug making new TidBits
  #     they get saved with a ~U[2021-11-09 02:45:44.567300Z] as "created",
  #     it needs to be a saved string timestamp
  # def new_tidbit(%Memelex.TidBit{} = t) do
  #   Memelex.WikiServer |> GenServer.call({:new_tidbit, t})
  # end


  #TODO TEMPORARILY - for the DEMO - I'm putting this here, but it should be deleted
  # def new_tidbit(p) do
  #   new(p)
  # end

  def new_tidbit(params) do
    params
    |> TidBitUtils.sanitize_conveniences()
    |> Memelex.TidBit.construct()
    |> new_tidbit()
  end

  def new_linked_tidbit(%{} = tidbit, params) do
    {:ok, new_tidbit} = 
      params
      |> Memelex.TidBit.construct()
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

  def save(%{tidbit_uuid: tidbit_uuid}) do
    Memelex.Fluxus.action({
      Memelex.Fluxus.Reducers.TidbitReducer,
      {:save_tidbit, %{tidbit_uuid: tidbit_uuid}}
    })
  end

  def save(%Memelex.TidBit{} = t) do
    Memelex.Fluxus.action({
      Memelex.Fluxus.Reducers.TidbitReducer,
      {:save_tidbit, t}
    })
  end

  def random do
    # fetch a random TidBit
    all() |> Enum.random()
  end

  @doc ~s(Return a list containing every single TidBit.)
  def all do
    {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)
    tidbits
  end

  def all_tags do
    # fetch a list of all the tags in the Memelex
    {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)

    Enum.reduce(tidbits, _tags_list = [], fn t, acc_tags ->
      acc_tags ++ t.tags
    end)
    |> Enum.uniq()
  end

  # def list(:external) do
  #   list() |> Enum.filter(& &1.type |> Enum.member?("external"))
  # end

  @doc """
  Used to get a unique list of one of the Wiki's sub fields,
  e.g. list(:tags) or list(:type)
  """ 

  # def list(search_term) when is_binary(search_term) do
  #   Memelex.WikiServer |> GenServer.call({:list_tidbits, search_term})
  # end

  # def list(params) when is_list(params) do
  #   {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)
  #   tidbits |> Enum.filter(&Memelex.Utils.Search.typed_and_tagged?(&1, params))
  # end

  #TODO `find` always tried to get exactly one tidbit returned

  def find!(%{tidbit_uuid: t_uuid}) when is_bitstring(t_uuid) do
    {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)
    case Enum.find(tidbits, :not_found, & &1.uuid == t_uuid) do
      :not_found ->
        raise "Could not find a TidBit with uuid: #{t_uuid}"
      %Memelex.TidBit{} = tidbit ->
        tidbit
    end
  end

  def find!(t_title) when is_bitstring(t_title) do
    {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)
    case Enum.find(tidbits, :not_found, & &1.title == t_title) do
      :not_found ->
        raise "Could not find a TidBit with title: #{t_title}"
      %Memelex.TidBit{} = tidbit ->
        tidbit
    end
  end

  # `search` can return multiple tidbits

  # always return multi-tidbit answer to a tags query
  # def find(%{tags: _t} = search_term) do
  #   Memelex.WikiServer |> GenServer.call({:list_tidbits, search_term})
  # end

  # def find(search_term) do
  #   {:ok, tidbit} = Memelex.WikiServer |> GenServer.call({:find_tidbit, search_term})
  #   tidbit
  # end

  # def find(search_term, opts) when is_list(opts) do
  #   {:ok, tidbit} = Memelex.WikiServer |> GenServer.call({:find_tidbit, search_term, opts})
  #   tidbit
  # end

  #TODO do a more intricate search & ranking algorithm in the future, but for now just look through the titles
  # In the future look for tags, & look in the content
  def search(tag: search_tag), do: search(tagged: search_tag)
  def search(tags: search_tag), do: search(tagged: search_tag)

  def search(tagged: search_tag) when is_bitstring(search_tag) do
    {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)
    Enum.filter(tidbits, &Enum.any?(&1.tags, fn t -> t == search_tag end))
  end

  def search(generic: search_term) do
    {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)

    similar_title_tidbits =
      Memelex.Utils.Search.title_search(tidbits, search_term)

    similar_data_tidbits =
      Memelex.Utils.Search.data_search(tidbits, search_term)

    similar_title_tidbits ++ similar_data_tidbits
  end

  def search(search_term, opts) when opts in [:t, :title, :titles] do
    search(generic: search_term)
    |> Enum.map(& &1.title)
  end

  def search(search_term) do
    search(generic: search_term)
  end



  # def open(params) do
  #   find(params) |> Memelex.Utils.ToolBag.open_external_textfile()
  # end

  def tag(%{tidbit_uuid: _t_uuid} = tidbit, new_tags) do
    # find!(tidbit) |> tag(new_tags) |> save()
    find!(tidbit) |> tag(new_tags)
  end

  def tag(%Memelex.TidBit{} = t, new_tags) do
    # add_tag(tidbit, tag)

    #TODO should we put this tidbit into edit mode, considering we aren't saving it???

    # we can't call edit & get back a tidbit, so we cant pass this tidbit into save
    # we can't call save after the fact, because then we will pass in the old tidbit & it wont save
    # the solution is to force it to save the tidbit in RadixState memory by giving it a specific uuid

    # edit(tidbit, %{add_tags: new_tags})
    # edit(tidbit, )
    # save(%{tidbit_uuid: tidbit.uuid})
    Memelex.Fluxus.action({TidbitReducer, {:update_tidbit, t, {:add_tags, new_tags}}})
  end

  #TODO I think this was created just to make it unique, but then it still adds clutter to list of functions so now I say remove it - it's a style change
  # def add_tag(tidbit, tag) when is_bitstring(tag) do
  #   edit(tidbit, %{add_tag: tag})
  # end

  @doc ~s(Create a link between two TidBits.)
  def link(base_node, link_node) do

    # links/backlinks are just saved lists of references to other TidBits
    # so first, we simply compute what those new lists will be
    new_base_node_links = base_node.links ++ [link_node |> Memelex.TidBit.construct_reference()]
    new_link_node_bases = link_node.backlinks ++ [base_node |> Memelex.TidBit.construct_reference()]

    # then we update each seperately - with the correct list of course!!
    Memelex.WikiServer |> GenServer.call({:update_tidbit, base_node, %{links: new_base_node_links}})
    Memelex.WikiServer |> GenServer.call({:update_tidbit, link_node, %{backlinks: new_link_node_bases}})

    :ok
  end

  def delete(tidbit) do
    GenServer.call(Memelex.WikiServer, {:delete_tidbit, tidbit})
  end
end
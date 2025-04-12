defmodule Memelex.My.Collections do
  @moduledoc """
  Collections is an API around the concept of ordered-groups of TidBits,
  e.g. an entire book could be represented as a structured collection
  of TidBits, or possibly as a collection of collections (one for each
  chapter). The "artfacts from Africa" and "photographs from summer
  vacation in Majorca" are also valid examples of collections.

  The first thing to note is that a Collection is itself a TidBit.
  There's nothing inherintly special about collections, they holding
  a piece of data just like any other - the only thing that's special
  about them is that this piece of data refers to an ordered arrangement
  of other TidBits.

  Collections can be defined in a number of ways. TiddlyWiki doesn't have
  a well-defined concept of a collection, they build the concept out of
  a tag-tree.

  We can also use tag-trees, or list of references, or other computed
  boils down to 2 cases
  - Computed (a function returns a list, could use tags or any other mechanism to compute the collection)
  - Recorded (a list of references)



  In the Memex, we represent Collections as list of lists - they can be
  heirarchical trees, but they can't be cyclical - that would be a graph,
  which is something different from a Collection - the ordering of a
  collection is important.

  """
  # alias Memelex.WikiServer
  # alias Memelex.Utils.TidBits
  alias Memelex.Lib.Structs.MemexConcepts.V01.Collection

  #   # note - collections, and tags, are the same thing! What we need is this https://tiddlywiki.com/#Order%20of%20Tagged%20Tiddlers

  # def new(params, tidbits), do: form(params, tidbits)

  # def form(params, tidbits) when is_list(tidbits) do
  #   params
  #   |> TidBits.ConstructorLogic.sanitize_conveniences()
  #   |> Map.merge(%{type: ["collection"], data: tidbits |> create_tidref_list()})
  #   |> Memelex.TidBit.new()
  #   |> Memelex.My.Wiki.new()
  # end

  # I basically need `new` & `add_to` for MVP

  # def new(name) when is_bitstring(name) do
  #   Memelex.My.Wiki.new(%{
  #     title: name,
  #     type: ["struct", Collection],
  #     data: Collection.new(%{"name" => name})
  #   })
  # end

  # This does the same thing as `new` it returns a TidBit, it just doesn't save it to the DB
  # the reason is because when we create a new tidbit through the GUI I want to be able to
  # instantiate the struct, but without actually creating it yet - think of it like a client
  # side validation, I _have_ to wait for the user to enter a valid name before I can save the Collection
  def new_draft do
    # create new TidBit struct without saving it in the Memex (to disk)
    #TODO hide this behind My.Wiki
    t = Memelex.TidBit.new(%{
      title: "unnamed",
      type: ["struct", Collection],
      data: Collection.new(%{"name" => "unnamed"})
    })

    # return the tuple so it cant easliy get confused with a real saved TidBit
    {:draft, t}
  end

  # def new_draft_item(collection_tidbit_uuid) do
  #   Memelex.TidBit.new(%{
  #     title: "unnamed",
  #     type: ["struct", Collection],
  #     data: Collection.new(%{"name" => "unnamed"})
  #   }, save?: true)
  # end

  # this should return all TidBits of type "collection" but filter out sub-collections
  def all do
    # TODO don't copyu entire wiki back here, do this inside the WikiServer process
    {:ok, wiki} = GenServer.call(Memelex.WikiServer, :list_all_tidbits)

    # TODO remove sub-sollections here
    is_collection? = fn
      %{type: ["struct", Collection]} ->
        true

      _otherwise ->
        false
    end

    wiki |> Enum.filter(is_collection?)
  end

  def all(opts) when opts in [:title, :t] do
    all() |> Enum.map(& &1.title)
  end

  def add_to(tidbit_uuid, %Memelex.TidBit{} = t) when is_binary(tidbit_uuid) do
    add_to(Memelex.My.Wiki.get!(tidbit_uuid), t)
  end

  # appends a tidbit to a collection
  def add_to(%Memelex.TidBit{data: %Collection{}} = collection_t, %Memelex.TidBit{} = t) do
    # TODO this should also add something to the tidbit we're adding, ...

    # put something in the metadata of the TidBit we're adding, about being part of a collection
    {:ok, _modified_t} =
      GenServer.call(Memelex.WikiServer, {:modify_tidbit, t, {:part_of_collection, collection_t}})

    # modify the collection to include the new item
    {:ok, modified_collection_t} =
      GenServer.call(Memelex.WikiServer, {:modify_tidbit, collection_t, %{add_item_to_this_collection: t}})

    modified_collection_t
  end

  # def create_tidref_list(tidbits) do
  #   recursively_create_list(tidbits, [])
  # end

  def fetch(title) when is_binary(title) do
    # TODO don't do this here do it inside wiki server lol
    case all() |> Enum.filter(&(&1.title == title)) do
      [] ->
        {:error, "No collection found with title: #{title}"}

      [collection] ->
        {:ok, collection}
    end
  end

  def force_refresh(%Memelex.TidBit{data: %Collection{}} = collection_t) do
    # go through the collection & refresh names etc
  end

  # def recursively_create_list([], tidrefs), do: tidrefs

  # def recursively_create_list([tidbit | rest], tidrefs) do
  #   recursively_create_list(rest, tidrefs ++ [tidbit |> Memelex.TidBit.construct_reference()])
  # end

  # def list do
  #   {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)

  #   tidbits
  #   |> Enum.filter(fn tidbit -> tidbit.type |> Enum.member?("collection") end)
  # end

  # NOTE - ok so, we could just do Collections as heirarchies of tags...

  # ok so - collections, are tags, are tidbits. When you open the TidBit
  # for a tag (all tags are TidBits) if you call My.Collections(tag) it
  # will attempt to list & order all the TidBits it finds:

  # https://tiddlywiki.narkive.com/mCC7sDrU/tw-tw5-question-about-tocs-trees-and-hierarchies-using-fields
end

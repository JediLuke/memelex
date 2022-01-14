defmodule Memelex.My.Collections do
  @moduledoc """
  Collections is an API around the concept of ordered-groups
  of TidBits, e.g. books - a list of chapters, which are in
  turn lists of pages - this is a collection of collections.

  The first thing to note is that a Collection is itself a TidBit.
  There's nothing inherintly special about collections, they holding
  a piece of data just like any other - the only thing that's special
  about them is that this piece of data refers to an ordered arrangement
  of other TidBits.

  One example of a Collection is a book - a book is a collection of Chapters,
  with a title and a few other pieces of data. There is a logical ordering
  to what goes in a book.

  The "artfacts from Africa" and "photographs from summer vacation in Majorca"
  are also valid examples of collections.

  In the Memex, we represent Collections as list of lists - they can beheirarchical
  trees, but they can't be cyclical - that would be a graph, which is something
  different from a Collection - the ordering of a collection is important.
  """
  alias Memelex.Env.WikiManager
  alias Memelex.Utils.TidBits.ConstructorLogic, as: TidBitUtils
  @snippets_tag "my_snippets"

  def form_new(params, tidbits) when is_list(tidbits) do
    params
    |> TidBitUtils.sanitize_conveniences()
    |> Map.merge(%{type: ["collection"], data: tidbits |> create_tidref_list()})
    |> Memelex.TidBit.construct()
    |> Memelex.My.Wiki.new_tidbit()
  end

  # appends a tidbit to a collection
  def add(%{uuid: uuid} = collection, tidbit) do

  end

  def create_tidref_list(tidbits) do
    recursively_create_list(tidbits, [])
  end

  def recursively_create_list([], tidrefs), do: tidrefs

  def recursively_create_list([tidbit|rest], tidrefs) do
    recursively_create_list(rest, tidrefs ++ [tidbit |> Memelex.TidBit.construct_reference()])
  end

  #NOTE - ok so, we could just do Collections as heirarchies of tags...


  # ok so - collections, are tags, are tidbits. When you open the TidBit
  # for a tag (all tags are TidBits) if you call My.Collections(tag) it
  # will attempt to list & order all the TidBits it finds:



  # https://tiddlywiki.narkive.com/mCC7sDrU/tw-tw5-question-about-tocs-trees-and-hierarchies-using-fields

end
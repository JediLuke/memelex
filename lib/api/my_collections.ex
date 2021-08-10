defmodule Memex.My.Collections do
  @moduledoc """
  Collections is an API around the concept of ordered-groups
  of TidBits, e.g. books - a list of chapters, which are in
  turn lists of pages - this is a collection of collections.
  """
  alias Memex.Env.WikiManager
  alias Memex.Utils.TidBits.ConstructorLogic, as: TidBitUtils
  @snippets_tag "my_snippets"

  def form_new(params, tidbits) when is_list(tidbits) do
    params
    |> TidBitUtils.sanitize_conveniences()
    |> Map.merge(%{type: ["collection"], data: tidbits |> create_tidref_list()})
    |> Memex.TidBit.construct()
    |> Memex.My.Wiki.new_tidbit()
  end

  # appends a tidbit to a collection
  def add(%{uuid: uuid} = collection, tidbit) do

  end

  def create_tidref_list(tidbits) do
    recursively_create_list(tidbits, [])
  end

  def recursively_create_list([], tidrefs), do: tidrefs

  def recursively_create_list([tidbit|rest], tidrefs) do
    recursively_create_list(rest, tidrefs ++ [tidbit |> Memex.TidBit.construct_reference()])
  end
end
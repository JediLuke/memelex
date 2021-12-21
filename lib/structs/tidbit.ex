defmodule Memex.TidBit do
  @moduledoc """
  modelled after the `tiddler` of TiddlyWiki.

  https://tiddlywiki.com/#TiddlerFields

  This module is really only supposed to contain the struct
  definition for TidBits. However, on the command-line, it
  it convenient/untuitive sometimes to think of things from
  a TidBit-centric perspective, e.g. `TidBit.new()` to make
  a new TidBit, so there are some functions declared here
  purely as API-sugar.
  """

  @enforce_keys [:uuid, :title, :created, :creator, :modified, :modifier]

  @derive Jason.Encoder

  defstruct [

      uuid:  nil,       # each tiddler has a UUID
      title: nil,       # the unique name for this tidbit
      data:  nil,       # the body text of the tidbit

      modified: nil,    # The time this tidbit was last modified
      modifier: nil,    # The name of the last person to modify this TidBit
      created:  nil,    # the date this tidbit was created
      creator:  nil,    # the name of the person who created ths TidBit

      type:      [],    # the content-type of a tidbit - a list of strings
      tags:      [],    # a list of tags associated with a TidBit
      links:     [],    # a list of all the linked TidBits
      backlinks: [],    # a list of all the Tidbits which link to this one

      status:  nil,     # an internal flag - we can "archive" TidBits this way

      history: nil,     # each time a TidBit changes, we track the history #TODO
      
      caption: nil,     # the text to be displayed in a tab or button
      meta:    [],      # a place to put extra data, e.g. `due_date`

      module: __MODULE__ # this allows us to reconstruct the correct Elixir struct from the JSON text files
  ]

  @doc ~s(This is here for the sake of the nice API: TidBit.new/1)
  def new(params) do
    Memex.My.Wiki.new_tidbit(params)
  end

  @doc ~s(This is here for the sake of the nice API: TidBit.update/2)
  def update(tidbit, params) do
    Memex.My.Wiki.update(tidbit, params)
  end

  def list do
    Memex.My.Wiki.list()
  end

  def find(search_term) do
    Memex.My.Wiki.find(search_term)
  end

  def open(%{type: ["external"|_rest]} = tidbit) do
    Memex.Utils.ToolBag.open_external_textfile(tidbit)
  end

  def link(base_node, link_node) do
    Memex.My.Wiki.link(base_node, link_node)
  end

  def tag(tidbit, tag) do
    add_tag(tidbit, tag)
  end

  def add_tag(tidbit, tag) do
    Memex.My.Wiki.add_tag(tidbit, tag)
  end

  def construct(params) do
    Memex.Utils.TidBits.ConstructorLogic.construct(params)
  end

  @doc ~s(When we need to reference a TidBit e.g. a list of TidBits, use this function to get the reference.)
  def construct_reference(%{title: t, uuid: uuid}) do
    %{title: t, uuid: uuid}
  end

  @doc ~s(This is the string format used to reference TidBits inside other TidBits.)
  def construct_link_string(%{title: t, uuid: uuid}) do
    "#{t}-[#{t}/#{uuid}]"
  end

end
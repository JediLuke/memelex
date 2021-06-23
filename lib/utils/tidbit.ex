defmodule Memex.TidBit do
  @moduledoc """
  modelled after the `tiddler` of TiddlyWiki.

  https://tiddlywiki.com/#TiddlerFields
  """

  def blank(params) do
    %{
      uuid: nil,            # each tiddler has a UUID
      name: nil,            # the unique name for this tidbit
      #title: nil,          # The display title of this tiddler, not necessarily unique
      text: nil,            # the body text of the tidbit
      modified: nil,        # The time this tidbit was last modified
      modifier: nil,        # The name of the last person to modify this TidBit
      created: nil,         # the date this tidbit was created
      creator: nil,         # the name of the person who created ths TidBit
      tags: nil,            # a list of tags ssociated with a TidBit
      type: nil,            # the content-type of a tidbit
      list: nil,            # a list of all the linked TidBits
      caption: nil,         # the text to be displayed in a tab or button
      #hash: nil            # my ambition is to hash each tiddler
    }
    |> Map.merge(params)
  end
end
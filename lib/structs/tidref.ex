defmodule Memex.TidRef do
  @moduledoc """
  A struct for holding references to TidBits.

  We need a struct so that we can save this info to disc,
  & by saving the module field in the map that goes to disc,
  we can get the struct back out later.
  """

  @enforce_keys [:uuid, :title]

  defstruct [

      uuid:   nil,         # each tiddler has a UUID
      title:  nil,         # The title of the TidBit we are referencing
      module: __MODULE__   # this allows us to reconstruct the correct Elixir struct from the JSON text files
  ]

end
defmodule Memex.TidRef do
  @moduledoc """
  A struct for holding references to TidBits/TidLinks.

  We need a struct so that we can save this info to disc,
  & by saving the module field in the map that goes to disc,
  we can get the struct back out later.
  """

  @enforce_keys [:uuid, :module]

  @derive Jason.Encoder

  defstruct [

      uuid:         nil,         # each tiddler has a UUID
      module:       nil,         # will be either TidBit or TidLink
      description:  nil,         # usually the title/label of the Tidex
      module:       __MODULE__   # this allows us to reconstruct the correct Elixir struct from the JSON text files
  ]


  #construct(%TidBit{} = t) do
  #  Kernel.struct(__MODULE__, valid_params |> convert_to_keyword_list())
  #end
end
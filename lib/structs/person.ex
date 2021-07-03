defmodule Memex.Person do
  @moduledoc """
  A struct for people.
  """

  @enforce_keys [:uuid]

  defstruct [

      uuid:     nil,   # each tiddler has a UUID
      name:     nil,   # The persons name, where the full name is an ordered-list of words e.g. ["Napoléon", "Bonaparte"]
      dob:      nil,   # D.O.B. = Date of Birth. The day the person was born
      contacts: [],    # a list of all the contacts I have for a person, e.g. [email: "mail@mail.co", phone: 123456]
      meta:     [],    # a field to add notes and any other metadata like maps - whatever really.
      tags:     [],    # similar to TidBits, people can have tags.
      links:    [],
      backlinks: [],
      module: __MODULE__ # this allows us to reconstruct the correct Elixir struct from the JSON text files
  ]

end
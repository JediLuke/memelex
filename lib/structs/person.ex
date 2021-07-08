defmodule Memex.Person do
  @moduledoc """
  A struct for people.
  """

  @enforce_keys [:uuid, :name]

  @derive Jason.Encoder

  defstruct [

      uuid:     nil,   # each tiddler has a UUID
      name:     nil,   # The persons name, where the full name is an ordered-list of words e.g. ["Napoléon", "Bonaparte"]
      nickname: nil,   # Same as above, list any nicknames
      dob:      nil,   # D.O.B. = Date of Birth. The day the person was born
      birthday: nil,   # The persons birthday
      contacts: [],    # a list of all the contacts I have for a person, e.g. [email: "mail@mail.co", phone: 123456]
      alive?:   nil,   # whether or not the person is currently alive
      meta:     [],    # a field to add notes and any other metadata like maps - whatever really.
      tags:     [],    # similar to TidBits, people can have tags.
      links:    [],
      backlinks: [],
      module: __MODULE__ # this allows us to reconstruct the correct Elixir struct from the JSON text files
  ]

  def construct(params) when is_map(params) do
    valid_params = validate(params)
    Kernel.struct!(__MODULE__, valid_params |> convert_to_keyword_list())
  end

  def validate(params) when is_map(params) do
    params
    |> generate_uuid()
    |> validate_name!()
  end 

  def generate_uuid(params) do
    params |> Map.merge(%{uuid: UUID.uuid4()})
  end

  def validate_name!(%{name: [n|_rest]} = params) when is_bitstring(n) do
    params
  end

  def validate_name!(_params) do
    raise "invalid name"
  end

  defp convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    map |> Keyword.new(fn {k,v} -> {k,v} end) # keys are already atoms
  end
end
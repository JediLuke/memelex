defmodule Memelex.Person do
  @moduledoc """
  A struct for people.
  """

  @enforce_keys [:uuid, :name]

  @derive Jason.Encoder

  defstruct [

      uuid:          nil,   # we require UUIDs for precision when pattern-matching
      name:          nil,   # The persons name, where the full name is an ordered-list of words e.g. ["Napoléon", "Bonaparte"]
      nickname:      nil,   # Same as above, list any nicknames
      birthday:      nil,   # The persons birthday
      birth_year:    nil,   # The year the person was born
      date_of_birth: nil,   # I know it's a bit redundant but why not
      contacts:      %{},   # a list of all the contacts I have for a person, e.g. %{email: "mail@mail.co", phone: 123456}
      alive?:        nil,   # whether or not the person is currently alive

      module: __MODULE__ # this allows us to reconstruct the correct Elixir struct from the JSON text files
  ]

  def construct(params) when is_map(params) do
    valid_params = validate(params)
    Kernel.struct(__MODULE__, valid_params |> convert_to_keyword_list())
  end

  def validate(params) when is_map(params) do
    params
    |> Memelex.Utils.ToolBag.generate_uuid()
    |> validate_name!()
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
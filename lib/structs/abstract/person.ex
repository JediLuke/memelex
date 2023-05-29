defmodule Memelex.Person do
  @moduledoc """
  A struct for people.
  """

  @derive Jason.Encoder

  defstruct [
      name:          nil,   # The persons name, where the full name is an ordered-list of words e.g. ["Napoléon", "Bonaparte"]
      nickname:      nil,   # Same as above, list any nicknames
      birthday:      nil,   # The persons birthday
      birth_year:    nil,   # The year the person was born
      contacts:      [],    # a list of all the contacts I have for a person, e.g. %{email: "mail@mail.co", phone: 123456}
      alive?:        nil,   # whether or not the person is currently alive
      notes:         []     # A list of (string) notes about this Person
  ]

  def construct(name) when is_bitstring(name) do
    construct(%{name: name})
  end

  def construct(params) when is_map(params) do
    valid_params = validate(params)
    Kernel.struct(__MODULE__, valid_params |> convert_to_keyword_list())
  end

  def dob(), do: date_of_birth()

  def date_of_birth() do
    raise "not implemented"
  end

  def validate(params) when is_map(params) do
    params
    # |> validate_name!()
  end

  def validate_name(name) when is_bitstring(name) do
    validate_name(%{name: name})
  end

  def validate_name!(%{name: n} = params) when is_bitstring(n) do
    params
  end

  def validate_name!(%{name: [n|_rest]} = params) when is_bitstring(n) do
    params
  end

  def validate_name!(_params) do
    raise "invalid name"
  end

  # defp convert_to_keyword_list(map) do
  #   # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
  #   map |> Keyword.new(fn {k,v} -> {k,v} end) # keys are already atoms
  # end

  defp convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    map |> Keyword.new(fn {k,v} -> {String.to_atom(k),v} end) #TODO figure out how to use `to_existing_atom` here (maybe? Maybe not worth it? just don't blow up the atom table :D)
  end
end

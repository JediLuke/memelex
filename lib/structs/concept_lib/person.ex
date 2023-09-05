defmodule Memelex.Person do
  @moduledoc """
  export ERL_AFLAGS="-kernel shell_history enabled"
  A struct for people.
  """

  @derive Jason.Encoder

  defstruct [
    # The persons name, where the full name is an ordered-list of words e.g. ["Napoléon", "Bonaparte"]
    name: nil,
    # Same as above, list any nicknames
    nickname: nil,
    # The persons birthday
    birthday: nil,
    # The year the person was born
    birth_year: nil,
    # a list of all the contacts I have for a person, e.g. %{email: "mail@mail.co", phone: 123456}
    contacts: [],
    # whether or not the person is currently alive
    alive?: nil,
    # A list of (string) notes about this Person
    notes: []
  ]

  def new(name) when is_bitstring(name) do
    new(%{name: name})
  end

  def new(params) when is_map(params) do
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

  def validate_name!(%{name: [n | _rest]} = params) when is_bitstring(n) do
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
    # TODO figure out how to use `to_existing_atom` here (maybe? Maybe not worth it? just don't blow up the atom table :D)
    map |> Keyword.new(fn {k, v} -> {String.to_atom(k), v} end)
  end
end

defmodule Memex.Password do
  @moduledoc """
  A struct for passwords.
  """

  @enforce_keys [:uuid, :label, :password]

  @derive Jason.Encoder

  defstruct [

      uuid:      nil,          # The UUID for this password
      label:     nil,          # How we describe this password, e.g. "DigitalOcean"
      username:  nil,          # The username associated with this password (if applicable)
      password:  nil,          # The password field goes in here
      url:       nil,          # The URL where this password can be used (if applicable)
      meta:      [],           # a field to add notes and any other metadata like maps - whatever really.
      tags:      [],           # similar to TidBits, passwords can have tags.
      links:     [],
      backlinks: [],
      module:    __MODULE__    # this allows us to reconstruct the correct Elixir struct from the JSON text files
  ]

  
  
  def construct(params) when is_map(params) do

    validated_params =
      params
      |> generate_uuid()
      |> label_is_valid!()
      |> password_is_valid!()
      |> validate_tags()

    Kernel.struct!(__MODULE__, validated_params |> convert_to_keyword_list())
  end

  def generate_uuid(params) do
    params |> Map.merge(%{uuid: UUID.uuid4()})
  end

  def label_is_valid!(%{label: l} = params) when is_bitstring(l) do
    params
  end
  def label_is_valid!(_else) do
    raise "invalid or missing label"
  end

  def password_is_valid!(%{password: p} = params) when is_bitstring(p) do
    params
  end
  def password_is_valid!(_else) do
    raise "invalid or missing password field"
  end

  def validate_tags(%{tags: tags} = params) when is_list(tags) do
    #TODO probably need a list of tags somewhere...
    if Enum.any?(tags, fn(tag) -> not is_bitstring(tag) end) do
      raise "one or more of the tags were not bitstrings"
    else
      params
    end
  end
  def validate_tags(params) do
    params
  end


  def convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    map |> Keyword.new(fn {k,v} -> {k,v} end) # keys are already atoms
  end
end
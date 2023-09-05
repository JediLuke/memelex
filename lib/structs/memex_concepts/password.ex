defmodule Memelex.Password do
  @moduledoc """
  A struct for passwords.
  """

  @enforce_keys [:label, :password]

  @derive Jason.Encoder

  defstruct [
    # TODO change label to title, should just be all the same... - do this in the API, when creating a password titbit just use same for both

    # we require UUIDs for precision when pattern-matching
    uuid: nil,
    # How we describe this password, e.g. "DigitalOcean"
    label: nil,
    # The username associated with this password (if applicable)
    username: nil,
    # The password field goes in here
    password: nil,
    # The URL where this password can be used (if applicable)
    url: nil,
    # Just a place you can store metadata
    meta: [],
    # this allows us to reconstruct the correct Elixir struct from the JSON text files
    module: __MODULE__
  ]

  def generate do
    Memelex.Utils.Encryption.generate_password(20)
  end

  def new(params) when is_map(params) do
    validated_params =
      params
      |> Memelex.Utils.ToolBag.generate_uuid()
      |> label_is_valid!()
      |> password_is_valid!()

    Kernel.struct(__MODULE__, validated_params |> convert_to_keyword_list())
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

  def convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    # keys are already atoms
    map |> Keyword.new(fn {k, v} -> {k, v} end)
  end
end

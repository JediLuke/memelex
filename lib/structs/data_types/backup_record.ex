defmodule Memex.BackupRecord do

  @enforce_keys [:uuid, :label, :date]

  @derive Jason.Encoder

  defstruct [

      uuid:      nil,          # we require UUIDs for precision when pattern-matching
      hash:      nil,          # take a hash of the entire backup #TODO
      label:     nil,          # How we describe this password, e.g. "DigitalOcean"
      date:      nil,          # The Date Time we took this Backup

      module:    __MODULE__    # this allows us to reconstruct the correct Elixir struct from the JSON text files
  ]

  def generate do
    Memex.Utils.Encryption.generate_password(20)
  end
  
  def construct(params) when is_map(params) do

    validated_params =
      params
      |> Memex.Utils.ToolBag.generate_uuid()
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
    map |> Keyword.new(fn {k,v} -> {k,v} end) # keys are already atoms
  end
end
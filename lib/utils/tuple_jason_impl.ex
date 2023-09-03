defimpl Jason.Encoder, for: Tuple do
  def encode(data, opts) when is_tuple(data) do
    Jason.Encode.list(Tuple.to_list(data), opts)
  end
end

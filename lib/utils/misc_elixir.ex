defmodule Memex.Utils.MiscElixir do


  def convert_map_to_keyword_list(map) when is_map(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    map |> Keyword.new(fn {k,v} when is_atom(k) -> {k,v} end) # keys are already atoms
  end

end
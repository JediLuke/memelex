defmodule Memex.Utils.DBMaintenance do

  @doc """
  This cleaner function goes through and convert TidBits which
  do not have types in lists, to ones that do have their type in a list.

  We probably don't ever need to use this again, but I did not start
  out using lists for types, so some TidBits just had strings as the type.
  """
  def listify_types do
    Memex.My.Wiki.list()
    |> Enum.each(fn 
         %Memex.TidBit{type: t} = tidbit when is_bitstring(t) ->
           Memex.My.Wiki.update(tidbit, %{type: [t]})
         %Memex.TidBit{type: l} when is_list(l) ->
           :ok # do nothing
         %Memex.TidBit{type: other} = tidbit ->
           raise "A very weird type was discovered on the TidBit: #{inspect tidbit.title}"
       end)
  end

end
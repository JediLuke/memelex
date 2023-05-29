# defmodule Memelex.Utils.DBMaintenance do

#   @doc """
#   This cleaner function goes through and convert TidBits which
#   do not have types in lists, to ones that do have their type in a list.

#   We probably don't ever need to use this again, but I did not start
#   out using lists for types, so some TidBits just had strings as the type.
#   """
#   def listify_types do
#     Memelex.My.Wiki.list()
#     |> Enum.each(fn
#          %Memelex.TidBit{type: t} = tidbit when is_bitstring(t) ->
#            Memelex.My.Wiki.update(tidbit, %{type: [t]})
#          %Memelex.TidBit{type: l} when is_list(l) ->
#            :ok # do nothing
#          %Memelex.TidBit{type: _other} = tidbit ->
#            raise "A very weird type was discovered on the TidBit: #{inspect tidbit.title}"
#        end)

#     # last check...
#     Memelex.My.Wiki.list()
#     |> Enum.each(fn tidbit -> if not is_list(tidbit.type), do: raise "One TidBit is not a list type!" end)
#   end

# end

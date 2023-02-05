defmodule Memelex.Fluxus.Reducers.RadixReducer do
   require Logger
   alias Memelex.Reducers.TidbitReducer


   def process(radix_state, {reducer, action}) when is_atom(reducer) do
      try do
         reducer.process(radix_state, action)
      rescue
         e in FunctionClauseError ->
         # IO.inspect e
         {:error, "#{__MODULE__} -- Reducer `#{inspect reducer}` could not match action: #{inspect action}"}
      end
   end

end
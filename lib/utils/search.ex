defmodule Memex.Utils.Search do
  require Logger
  
  @similarity_cutoff 0.72

  def tidbits(wiki, %{uuid: search_uuid}) do
    
    search_fn = fn tidbit -> tidbit.uuid == search_uuid end
    
    wiki
    |> Enum.find(:not_found, search_fn) 
    |> case do
         :not_found -> {:error, "could not find any TidBit with a this UUID"}
            results -> {:ok, results}
    end
  end

  def tidbits(wiki, map) when is_map(map) do
    raise "no maps, only keyword lists"
  end

  def tidbits(wiki, search_term) when is_binary(search_term) do
    search_fn = fn tidbit -> String.jaro_distance(search_term, tidbit.title) >= @similarity_cutoff end
    
    wiki
    |> Enum.find(:not_found, search_fn) 
    |> case do
         :not_found -> {:error, "could not find any TidBit with a title similar to: #{inspect search_term}"}
            results -> {:ok, results}
    end
  end

  def tidbits(_wiki, []) do
    {:error, "no search params passed"}
  end

  def tidbits(wiki, search_params) when is_list(search_params) and length(search_params) >= 1 do

    search_fn = fn tidbit -> typed_and_tagged?(tidbit, search_params) end
    
    wiki
    |> Enum.find(:not_found, search_fn) 
    |> case do
         :not_found -> {:error, "could not find any TidBit with params: #{inspect search_params}"}
            results -> {:ok, results}
    end
  end

  def typed_and_tagged?(_tidbit, []) do
    #NOTE: This function
    #      is used as a filter recursively, and the base case (no tags)
    #      means we've cycled through all our search terms, so we return true.
    #      plus - logically it kind of makes sense, that a TidBit (by default ~ it's obviously true)
    #      is "types and tagged" by the filter of "no specification"
    #
    #      We have the guard for this case in place anyway since `tidbits(wiki, [])`
    #      returns an error.
    true
  end

  # all tidbits that aren't tagged
  def typed_and_tagged?(tidbit, [{:tags, []} |rest]) do
    if tidbit.tags == [] do
      typed_and_tagged?(tidbit, rest)
    else
      false
    end
  end

  def typed_and_tagged?(tidbit, [{param, test_list} |rest]) when is_list(test_list) and length(test_list) >= 1 do
    if Map.get(tidbit, param) |> recurse_contains_all?(test_list) do
      typed_and_tagged?(tidbit, rest)
    else
      false
    end
  end

  defp recurse_contains_all?(_test_list, []) do
    #NOTE: when we recurse through the list, getting an empty list means we DID
    #      contain all the tags, so we want to return true. (base case)
    true
  end

  defp recurse_contains_all?(test_list, [test_item|rest]) do
    if test_list |> Enum.member?(test_item) do
      recurse_contains_all?(test_list, rest) # continue the testing...
    else
      false # we did not find an item, so we do not contain all the test_items
    end
  end

end
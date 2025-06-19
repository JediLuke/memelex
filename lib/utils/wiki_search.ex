defmodule Memelex.Utils.WikiSearch do
  require Logger

  @jaro_cutoff 0.67

  def find_one(wiki, search_term) when is_binary(search_term) do
    wiki
    # TODO look at things other than title eventually
    |> Enum.sort_by(&String.jaro_distance(search_term, &1.title || ""), :desc)
    |> case do
      [] ->
        {:error, "Unable to find TidBit."}

      [tidbit | _rest] ->
        {:ok, tidbit}
    end
  end

  def find_one(wiki, tagged: tag) when is_binary(tag) do
    wiki |> tag_search(all_of: [tag])
  end

  def find_one(wiki, %{"uuid" => t_uuid}) do
    wiki |> Enum.filter(&(&1.uuid == t_uuid))
  end

  @doc """
  Finds elements in `wiki` tagged with a single `tag`.

  ## Examples

      iex> wiki = [%{tags: ["science", "math"]}, %{tags: ["art"]}, %{tags: ["science"]}]
      iex> Memelex.Utils.WikiSearch.find_all(wiki, tagged: "science")
      [%{tags: ["science", "math"]}, %{tags: ["science"]}]

  """
  def find_all(wiki, tagged: tag) when is_binary(tag) do
    find_all(wiki, tagged: [tag])
  end

  def find_all(wiki, tagged: tags) when is_list(tags) do
    wiki |> tag_search(all_of: tags)
  end

  def find_all(wiki, search_term) when is_binary(search_term) do
    find_all(wiki, search_term, %{"cutoff" => @jaro_cutoff, "max_t" => 50})
  end

  def find_all(wiki, search_term, %{"cutoff" => cutoff, "max_t" => max_t})
      when is_binary(search_term) and is_integer(max_t) do
    wiki
    # # TODO look at things other than title eventually
    # |> Enum.filter(fn tidbit ->
    #   String.jaro_distance(search_term, tidbit.title) >= cutoff
    # end)
    # |> Enum.sort_by(&String.jaro_distance(search_term, &1.title), :desc)
    # # ...
    |> Enum.filter(&(String.jaro_distance(search_term, &1.title || "") >= cutoff))
    |> Enum.sort_by(&String.jaro_distance(search_term, &1.title || ""), :desc)
    |> Enum.take(max_t)
  end

  @doc """
  Finds elements in `wiki` tagged with any of the `tags`.

  ## Examples

      iex> wiki = [%{tags: ["science", "math"]}, %{tags: ["art"]}, %{tags: ["science"]}]
      iex> Memelex.Utils.WikiSearch.find_all(wiki, tagged: ["science", "art"])
      [%{tags: ["science", "math"]}, %{tags: ["art"]}, %{tags: ["science"]}]

  """

  def find_any(wiki, tags: tags) when is_list(tags) do
    wiki |> tag_search(any_of: tags)
  end

  # # we dont want searching for a list empty tags to return everything
  # # it looks confusing because we need to filter-match the `any_of/all_of`
  # # term, but don't be fooled, it's just handling the case where
  # # someone looks for `tagged: []`, which IMHO should return nothing
  # def tag_search(_wiki, [{_conjunction_term, _tags = []}]) do
  #   []
  # end

  def tag_search(_wiki = [], _tags_query), do: []

  def tag_search(wiki, any_of: [tag | rest]) when is_binary(tag) do
    new_results = wiki |> Enum.filter(&is_tagged_with?(&1, tag))
    tag_search(wiki, any_of: rest) ++ new_results
  end

  # in this case, TidBits must have ALL the tags given
  def tag_search(wiki, all_of: tags) when length(tags) >= 1 do
    Enum.reduce(tags, wiki, fn tag, acc ->
      Enum.filter(acc, &is_tagged_with?(&1, tag))
    end)
  end

  def tag_search(wiki, :all_untagged) do
    wiki |> Enum.filter(fn tidbit -> tidbit.tags == [] end)
  end

  # defp do_tag_search(wiki, _tags = []), do: wiki

  # defp do_tag_search(wiki, [tag | rest], results) when is_binary(tag) do
  #   # new_results = wiki |> Enum.filter(&is_tagged_with?(&1, tag))
  #   # do_tag_search(wiki, rest, results ++ new_results)
  #   wiki
  #   |> Enum.filter(&is_tagged_with?(&1, tag))

  #   do_tag_search(new_wiki, rest, results)
  # end

  def is_tagged_with?(%Memelex.TidBit{} = tidbit, tag) when is_binary(tag) do
    tidbit.tags |> Enum.member?(tag)
  end

  # def do_tag_search(wiki, _tags = [], results), do: results

  # def do_tag_search(wiki, [tag | rest], results) when is_binary(tag) do
  #   wiki
  #   |> Enum.filter(&is_tagged_with?(&1, tag))
  #   |> do_tag_search(rest, results)
  # end

  # def is_tagged_with?(tidbit, tag) do
  #   tidbit.tags |> Enum.member?(tag)
  # end

  # @default_similarity_cutoff 0.67
  # def title_search(tidbits, search_term, similarity_cutoff \\ @default_similarity_cutoff) do
  #   Enum.filter(
  #     tidbits,
  #     &closer_than_jaro(&1.title, search_term, similarity_cutoff)
  #   )
  # end

  # def title_contains_search(tidbits, search_term) do
  #   Enum.filter(tidbits, &String.contains?(&1.title, search_term))
  # end

  # @data_similarity_cutoff 0.5
  # def data_search(tidbits, search_term) do
  #   tidbits
  #   |> Enum.filter(fn
  #     %{type: ["text"], data: body} when is_bitstring(body) ->
  #       true

  #     _otherwise ->
  #       false
  #   end)
  #   # TODO instead of just contains, we should fuzzy-find around the search-term aswell!!
  #   |> Enum.filter(&String.contains?(&1.data, search_term))
  # end

  def closer_than_jaro(text_to_search, search_term, similarity_cutoff) do
    jaro_dist = String.jaro_distance(search_term, text_to_search)
    jaro_dist >= similarity_cutoff
  end

  # #NOTE - singular TidBit
  # def one_tidbit(wiki, %{uuid: search_uuid}) do
  #   search_fn = fn tidbit -> tidbit.uuid == search_uuid end

  #   wiki
  #   |> Enum.find(:not_found, search_fn)
  #   |> case do
  #        :not_found -> {:error, "Could not find any TidBit with a this UUID"}
  #           results -> {:ok, results}
  #   end
  # end

  # def one_tidbit(wiki, search_term) when is_binary(search_term) do
  #   results =
  #     wiki
  #     |> Enum.filter(
  #          fn tidbit -> String.jaro_distance(search_term, tidbit.title) >= @similarity_cutoff end)

  #   # just return the first one I guess
  #   #TODO can probably use List.first or something better here
  #   if results == [] do
  #     {:error, "Unable to find TidBit."}
  #   else
  #     {:ok, hd(results)}
  #   end
  # end

  # def one_tidbit(wiki, {:exact, search_term}) when is_binary(search_term) do
  #   results =
  #     wiki
  #     |> Enum.filter(
  #          fn tidbit -> search_term == tidbit.title end)

  #   # just return the first one I guess
  #   #TODO can probably use List.first or something better here
  #   if results == [] do
  #     {:error, "Unable to find TidBit."}
  #   else
  #     {:ok, hd(results)}
  #   end

  # end

  # def tidbits(_wiki, []) do
  #   {:error, "no search params passed"}
  # end

  # def tidbits(wiki, map) when is_map(map) do
  #   keyword_params = Memelex.Utils.MiscElixir.convert_map_to_keyword_list(map)
  #   tidbits(wiki, keyword_params)
  # end

  # def tidbits(wiki, search_params) when is_list(search_params) and length(search_params) >= 1 do
  #   results =
  #     wiki
  #     |> Enum.filter(
  #          fn tidbit -> typed_and_tagged?(tidbit, search_params) end)

  #   {:ok, results}
  # end

  # TODO pretty sure under here is not useful, or could be refactored... I can't remember exactly
  # what it was for, I think it was to filter by tag? But to construct a tag-tree maybe?? Why all the recursion??

  def typed_and_tagged?(_tidbit, []) do
    # NOTE: This function
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
  def typed_and_tagged?(tidbit, [empty_tagslist | rest])
      when empty_tagslist in [{:tags, []}, [tags: []]] do
    if tidbit.tags == [] do
      typed_and_tagged?(tidbit, rest)
    else
      false
    end
  end

  def typed_and_tagged?(tidbit, [{param, test_list} | rest])
      when is_list(test_list) and length(test_list) >= 1 do
    if Map.get(tidbit, param) |> recurse_contains_all?(test_list) do
      typed_and_tagged?(tidbit, rest)
    else
      false
    end
  end

  def typed_and_tagged?(tidbit, [[param, test_list] | rest])
      when is_list(test_list) and length(test_list) >= 1 do
    if Map.get(tidbit, param) |> recurse_contains_all?(test_list) do
      typed_and_tagged?(tidbit, rest)
    else
      false
    end
  end

  def typed_and_tagged?(tidbit, [[param, test_list] | rest])
      when is_list(test_list) and length(test_list) >= 1 do
    if Map.get(tidbit, param) |> recurse_contains_all?(test_list) do
      typed_and_tagged?(tidbit, rest)
    else
      false
    end
  end

  defp recurse_contains_all?(_test_list, []) do
    # NOTE: when we recurse through the list, getting an empty list means we DID
    #      contain all the tags, so we want to return true. (base case)
    true
  end

  defp recurse_contains_all?(test_list, [test_item | rest]) do
    if test_list |> Enum.member?(test_item) do
      # continue the testing...
      recurse_contains_all?(test_list, rest)
    else
      # we did not find an item, so we do not contain all the test_items
      false
    end
  end

  # ====

  # def list(:external) do
  #   list() |> Enum.filter(& &1.type |> Enum.member?("external"))
  # end
  # def list(params) when is_list(params) do
  #   {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)
  #   tidbits |> Enum.filter(&Memelex.Utils.Search.typed_and_tagged?(&1, params))
  # end

  # TODO `find` always tried to get exactly one tidbit returned

  # def find(%{tidbit_uuid: t_uuid}) when is_bitstring(t_uuid) do
  #   find(%{uuid: t_uuid})
  # end

  # def find(%{uuid: t_uuid}) when is_bitstring(t_uuid) do
  #   case Enum.find(all(), :not_found, &(&1.uuid == t_uuid)) do
  #     :not_found ->
  #       Logger.debug("Could not find a TidBit with uuid: #{t_uuid}")
  #       nil

  #     %Memelex.TidBit{} = tidbit ->
  #       tidbit
  #   end
  # end

  # def find(search_term) do
  #   # first check of it's a UUID
  #   case find(%{uuid: search_term}) do
  #     nil ->
  #       # if it's not a UUID, then it's a title
  #       generic_search(search_term)

  #     %Memelex.TidBit{} = tidbit ->
  #       tidbit
  #   end
  # end

  # def find!(search_term) do
  #   case find(search_term) do
  #     nil ->
  #       raise "Could not find a TidBit with search term: #{search_term}"

  #     %Memelex.TidBit{} = tidbit ->
  #       tidbit
  #   end
  # end

  # def find!(%{tidbit_uuid: t_uuid}) when is_bitstring(t_uuid) do
  # end

  # def find!(t_title) when is_bitstring(t_title) do
  #   case Enum.find(all(), :not_found, &(&1.title == t_title)) do
  #     :not_found ->
  #       raise "Could not find a TidBit with title: #{t_title}"

  #     %Memelex.TidBit{} = tidbit ->
  #       tidbit
  #   end
  # end

  # # TODO do a more intricate search & ranking algorithm in the future, but for now just look through the titles
  # # In the future look for tags, & look in the content
  # # def search(tag: search_tag), do: search(tagged: search_tag)
  # # def search(tags: search_tag), do: search(tagged: search_tag)

  # # this search tries a combination of strategies to just always try and give back the best answer for looking up a tidbit
  # def generic_search(search_term) do
  #   {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)

  #   tidbits_with_a_title_containing_the_keyword =
  #     Memelex.Utils.Search.title_contains_search(tidbits, search_term)

  #   if tidbits_with_a_title_containing_the_keyword == [] do
  #     # look a bit wider
  #     Memelex.Utils.Search.title_search(tidbits, search_term) ++
  #       Memelex.Utils.Search.data_search(tidbits, search_term)
  #   else
  #     tidbits_with_a_title_containing_the_keyword
  #   end
  # end

  # def search(generic: search_term) do
  #   {:ok, tidbits} = Memelex.WikiServer |> GenServer.call(:list_all_tidbits)

  #   similar_title_tidbits = Memelex.Utils.Search.title_search(tidbits, search_term)

  #   similar_data_tidbits = Memelex.Utils.Search.data_search(tidbits, search_term)

  #   similar_title_tidbits ++ similar_data_tidbits
  # end

  # def search(search_term, opts) when opts in [:t, :title, :titles] do
  #   search(generic: search_term)
  #   |> Enum.map(& &1.title)
  # end

  # def search(search_term) do
  #   search(generic: search_term)
  # end
end

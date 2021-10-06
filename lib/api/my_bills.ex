defmodule Memex.My.Bills do
  alias Memex.Env.WikiManager


  def new(%{tags: tlist} = params) when is_list(tlist) do
    validate_tag_list!(tlist)
    params
    |> Map.merge(%{tags: tlist ++ ["my_bills"]})
    |> Memex.My.Wiki.new_tidbit()
  end

  def new(params) when is_map(params) do
    params
    |> Map.merge(%{tags: ["my_bills"]})
    |> Memex.My.Wiki.new_tidbit()
  end

  @doc ~s(Fetch the whole list of TODOs)
  def list do
    {:ok, tidbits} =
      WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)

    tidbits
    |> Enum.filter(fn(tidbit) -> tidbit.tags |> Enum.member?("my_bills") end)
  end

  defp validate_tag_list!([]) do
    true
  end
  defp validate_tag_list!([tag|rest]) when is_bitstring(tag) do
    validate_tag_list!(rest)
  end
  defp validate_tag_list!([tag|_rest]) do # matches anything besides a string 
    context = %{invalid_tag: tag}
    raise "an invalid tag was passed in via the tag list. #{inspect context}"
  end

end
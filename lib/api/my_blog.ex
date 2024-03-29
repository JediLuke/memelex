defmodule Memelex.My.Blog do
  alias Memelex.WikiServer

  def new_idea(title) when is_bitstring(title) do
    new_idea(%{title: title})
  end

  def new_idea(%{tags: tlist} = params) when is_list(tlist) do
    validate_tag_list!(tlist)
    params
    |> Map.merge(%{tags: tlist ++ ["my_blog", "ideas"]})
    |> Memelex.My.Wiki.new()
  end

  def new_idea(params) when is_map(params) do
    params
    |> Map.merge(%{tags: ["my_blog", "ideas"]})
    |> Memelex.My.Wiki.new()
  end

  @doc ~s(Fetch the whole list of TODOs)
  def ideas do
    {:ok, tidbits} =
      WikiManager |> GenServer.call(:list_all_tidbits)

    tidbits
    |> Enum.filter(
        fn(tidbit) ->
          tidbit.tags |> Enum.member?("my_blog")
            and
          tidbit.tags |> Enum.member?("ideas")
        end)
  end


  def validate_tag_list!([]) do
    true
  end
  def validate_tag_list!([tag|rest]) when is_bitstring(tag) do
    validate_tag_list!(rest)
  end
  def validate_tag_list!([tag|_rest]) do # matches anything besides a string 
    context = %{invalid_tag: tag}
    raise "an invalid tag was passed in via the tag list. #{inspect context}"
  end

end


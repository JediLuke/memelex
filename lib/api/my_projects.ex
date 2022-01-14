defmodule Memelex.My.Projects do
  alias Memelex.Env.WikiManager

  def new(title) when is_bitstring(title) do
    new(%{title: title})
  end

  def new(%{tags: tlist} = params) when is_list(tlist) do
    Memelex.Utils.Tags.validate_tag_list!(tlist)
    params
    |> Map.merge(%{tags: tlist ++ ["my_projects"]})
    |> Memelex.My.Wiki.new_tidbit()
  end

  def new(params) do
    params
    |> Map.merge(%{tags: ["my_projects"]})
    |> Memelex.My.Wiki.new_tidbit()
  end

  def new(title, keyword_list) when is_bitstring(title) and is_list(keyword_list) do
    new(%{title: title} |> Map.merge(keyword_list |> Enum.into(%{})))
  end

  def list do
    {:ok, wiki} = GenServer.call(WikiManager, :can_i_get_a_list_of_all_tidbits_plz)
    wiki |> Enum.filter(
      fn tidbit -> tidbit.tags |> Enum.member?("my_projects") end
    )
  end

end
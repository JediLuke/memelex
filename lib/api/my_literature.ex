defmodule Memex.My.Literature do
  alias Memex.Env.WikiManager

  def new_idea(title) when is_bitstring(title) do
    new_idea(%{title: title})
  end

  def new_idea(%{tags: tlist} = params) when is_list(tlist) do
    Memex.Utils.Tags.validate_tag_list!(tlist)
    params
    |> Map.merge(%{tags: tlist ++ ["my_literature", "ideas"]})
    |> Memex.My.Wiki.new_tidbit()
  end

  def new_idea(params) when is_map(params) do
    params
    |> Map.merge(%{tags: ["my_literature", "ideas"]})
    |> Memex.My.Wiki.new_tidbit()
  end

  def ideas do
    {:ok, tidbits} =
       GenServer.call(WikiManager, :can_i_get_a_list_of_all_tidbits_plz)

    tidbits
    |> Enum.filter(
        fn(tidbit) ->
          tidbit.tags |> Enum.member?("my_literature")
            and
          tidbit.tags |> Enum.member?("ideas")
        end)
  end

end
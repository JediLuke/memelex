defmodule Memelex.My.Literature do
  alias Memelex.Env.WikiManager

  def new_idea(title) when is_bitstring(title) do
    new_idea(%{title: title})
  end

  def new_idea(%{tags: tlist} = params) when is_list(tlist) do
    Memelex.Utils.Tags.validate_tag_list!(tlist)
    params
    |> Map.merge(%{tags: tlist ++ ["my_literature", "ideas"]})
    |> Memelex.My.Wiki.new_tidbit()
  end

  def new_idea(params) when is_map(params) do
    params
    |> Map.merge(%{tags: ["my_literature", "ideas"]})
    |> Memelex.My.Wiki.new_tidbit()
  end

  def ideas do
    {:ok, tidbits} =
       GenServer.call(WikiManager, :list_all_tidbits)

    tidbits
    |> Enum.filter(
        fn(tidbit) ->
          tidbit.tags |> Enum.member?("my_literature")
            and
          tidbit.tags |> Enum.member?("ideas")
        end)
  end

end
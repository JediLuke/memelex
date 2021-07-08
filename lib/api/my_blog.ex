defmodule Memex.My.Blog do
  alias Memex.Env.WikiManager

  def new_idea(title) when is_bitstring(title) do
    new_idea(%{title: title})
  end

  def new_idea(params) when is_map(params) do
    params
    |> Map.merge(%{tags: ["my_blog", "idea"]})
    |> Memex.My.Wiki.new_tidbit()
  end

  @doc ~s(Fetch the whole list of TODOs)
  def ideas do
    {:ok, tidbits} =
      WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)

    tidbits
    |> Enum.filter(
        fn(tidbit) ->
          tidbit.tags |> Enum.member?("my_blog")
            and
          tidbit.tags |> Enum.member?("idea")
        end)
  end

end


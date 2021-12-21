defmodule Memex.My.Docs do
  alias Memex.Env.WikiManager

  @tag "my_docs"

  def new(%{tags: tlist} = params) when is_list(tlist) do
    Memex.Utils.Validation.validate_tag_list!(tlist)
    params
    |> Map.merge(%{tags: tlist ++ [@tag]})
    |> Memex.My.Wiki.new_tidbit()
  end

  def new(params) when is_map(params) do
    params
    |> Map.merge(%{tags: [@tag]})
    |> Memex.My.Wiki.new_tidbit()
  end

  @doc ~s(Fetch the whole list of TODOs)
  def list do
    {:ok, tidbits} =
      WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)

    tidbits
    |> Enum.filter(fn(tidbit) -> tidbit.tags |> Enum.member?(@tag) end)
  end

end
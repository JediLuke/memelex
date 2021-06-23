defmodule Memex.My.TODOs do
  alias Memex.Env.WikiManager

  def new(%{tags: tlist} = params) when is_list(tlist) do
    params
    |> Map.merge(%{tags: tlist ++ ["#TODO"]})
    |> Memex.My.Wiki.new()
  end

  @doc ~s(Fetch the whole list of TODOs)
  def list do

    {:ok, tidbits} =
      WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)

    if tidbits == [] do
      []
    else
      # this filtering function is used to find tidbits tagged with "#TODO"
      only_todos = fn(tidbit) -> tidbit.tags |> Enum.member?("#TODO") end
      tidbits |> Enum.filter(only_todos)
    end
  end
  
end
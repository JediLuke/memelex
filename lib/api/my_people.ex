defmodule Memex.My.People do
  alias Memex.Env.WikiManager

  def new(params) do
    new_person = params |> Memex.Person.construct()
    Memex.My.Wiki.new_tidbit(%{type: :person, data: new_person})
  end

  @doc ~s(Fetch the whole list of TODOs)
  def list do
    {:ok, tidbits} =
      WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)

    tidbits
    |> Enum.filter(fn(tidbit) -> tidbit.type |> Enum.member?("person") end)
  end

end
defmodule Memelex.My.People do
  alias Memelex.Env.WikiManager

  def new(params) do
    new_person = params |> Memelex.Person.construct()
    Memelex.My.Wiki.new_tidbit(params |> Map.merge(%{type: :person, data: new_person}))
  end

  def add(params) do
    new(params)
  end

  @doc ~s(Fetch the whole list of TODOs)
  def list do
    {:ok, tidbits} =
      WikiManager |> GenServer.call(:list_all_tidbits)

    tidbits
    |> Enum.filter(fn(tidbit) -> tidbit.type |> Enum.member?("person") end)
  end

end
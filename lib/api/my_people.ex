defmodule Memelex.My.People do

  def new(name) when is_bitstring(name) do
    new_person = Memelex.Person.construct(name)

    Memelex.My.Wiki.new(%{
      title: name,
      type: {:struct, Memelex.Person},
      data: new_person
    })
  end

  def add(params) do
    new(params)
  end

  @doc ~s(Fetch the whole list of TODOs)
  def list do
    {:ok, tidbits} =
      Memelex.WikiServer |> GenServer.call(:list_all_tidbits)

    tidbits
    |> Enum.filter(fn(tidbit) -> tidbit.type |> Enum.member?("person") end)
  end

end

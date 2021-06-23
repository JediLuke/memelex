defmodule Memex.My.Wiki do
  alias Memex.Env.WikiManager

  def new(%Memex.TidBit{} = t) do
    WikiManager |> GenServer.call({:new_tidbit, t})
  end

  def new(params) do
    params
    |> Memex.TidBit.construct()
    |> new()
  end


  def list do
    {:ok, tidbits} = WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)
    tidbits
  end

end
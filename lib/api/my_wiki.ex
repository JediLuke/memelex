defmodule Memex.My.Wiki do
  alias Memex.Env.WikiManager


  def list do
    {:ok, tidbits} = WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)
    tidbits
  end
  
end
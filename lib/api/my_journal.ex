defmodule Memex.My.Journal do
  alias Memex.Env.WikiManager

  @doc ~s(Opens today's Journal entry.)
  def today do

    {:ok, tidbits} =
            WikiManager
            |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)

    # this filtering function is used to find tidbits tagged with "my_journal"
    only_journal_entries =
            fn(tidbit) -> tidbit.tags |> Enum.member?("my_journal") end

    journal_entries =
            tidbits |> Enum.filter(only_journal_entries)
    
    # this filtering function is used to find today's entry
    # from the above list of Journal entries 
    todays_entry =
            fn(tidbit) -> tidbit.tags |> Enum.member?("Wed 23 June 2021") end

    todays_entry = journal_entries |> Enum.find(todays_entry)

    if todays_entry == nil do
      raise "Need to make a new entry here..."
    else
      todays_entry
    end
  end
  
  def now do
    raise "this should open todays entry but also add a timestamp for now"
  end
end
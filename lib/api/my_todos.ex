defmodule Memex.My.TODOs do
  alias Memex.Env.WikiManager

  # we override here to allow a user to just type in a single
  # string, and we will accept it and turn it into a list
  def new(%{tags: tag} = params) when is_bitstring(tag) do
    %{params|tags: [tag]} |> new()
  end

  def new(%{tags: tlist} = params) when is_list(tlist) do
    validate_tag_list!(tlist)
    params
    |> Map.merge(%{tags: tlist ++ ["#TODO"]})
    |> Memex.My.Wiki.new_tidbit()
  end

  # this is a nice convenience function, make a TODO in one line
  def new(title) when is_bitstring(title) do
    new(%{title: title})
  end

  def new(params) do
    params
    |> Map.merge(%{tags: ["#TODO"]})
    |> Memex.My.Wiki.new_tidbit()
  end

  # more convenient to use keyword lists on the CLI
  def new(title, [tags: tlist]) when is_bitstring(title) do
    new(%{title: title, tags: tlist})
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
  
  def validate_tag_list!([]) do
    true
  end
  def validate_tag_list!([tag|rest]) when is_bitstring(tag) do
    validate_tag_list!(rest)
  end
  def validate_tag_list!([tag|_rest]) do # matches anything besides a string 
    context = %{invalid_tag: tag}
    raise "an invalid tag was passed in via the tag list. #{inspect context}"
  end


end
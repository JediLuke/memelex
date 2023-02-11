defmodule Memelex.My.TODOs do
  alias Memelex.WikiServer


  # This function should return some helpful advice for the user on how
  # to make a new TODO
  def new do
    ~s(To add a new TODO, all you need to provide is a titleHere's how to make a new TODO:

       Memelex.My.TODOs.new "Mow the lawn"

       There are more ways to make TODOs. Check out #{__MODULE__} for more
       information.)
  end

  def new(title, data) when is_bitstring(title) do
    new(%{title: title, data: data})
  end

  # we override here to allow a user to just type in a single
  # string, and we will accept it and turn it into a list
  def new(%{tags: tag} = params) when is_bitstring(tag) do
    %{params|tags: [tag]} |> new()
  end

  #TODO we need to incorporate something like priority, or due date

  def new(%{tags: tlist} = params) when is_list(tlist) do
    validate_tag_list!(tlist)
    params
    |> Map.merge(%{tags: tlist ++ ["#TODO"]})
    |> Memelex.My.Wiki.new()
  end

  # this is a nice convenience function, make a TODO in one line
  def new(title) when is_bitstring(title) do
    new(%{title: title})
  end

  def new(params) do
    params
    |> Map.merge(%{tags: ["#TODO"]})
    |> Memelex.My.Wiki.new()
  end

  # more convenient to use keyword lists on the CLI
  def new(title, [tags: tlist]) when is_bitstring(title) do
    new(%{title: title, tags: tlist})
  end

  # I have gone to type this a few times, so just make it available and call new/1
  def add(params) do
    new(params)
  end

  @doc ~s(Fetch the whole list of TODOs)
  def list do

    {:ok, tidbits} =
      WikiManager |> GenServer.call(:list_all_tidbits)


    #TODO check this works even with an empty TidBit list
    # this filtering function is used to find tidbits tagged with "#TODO"
    only_todos = fn(tidbit) -> tidbit.tags |> Enum.member?("#TODO") end
    tidbits |> Enum.filter(only_todos)
  end

  def random do
    {:ok, tidbits} =
      WikiManager |> GenServer.call(:list_all_tidbits)
    
    only_todos = fn(tidbit) -> tidbit.tags |> Enum.member?("#TODO") end
    
    tidbits
    |> Enum.filter(only_todos)
    |> Enum.random()
  end

  def mark_complete(%{uuid: uuid}) do
    raise "can't mark TODOs as complete yet"
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
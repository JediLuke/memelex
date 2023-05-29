defmodule Memelex.My.TODOs do
  alias Memelex.WikiServer

  @tag "#TODO"

  def tag, do: @tag

  # just convenience API functions
  defdelegate find(search_term), to: Memelex.My.Wiki
  defdelegate update(tidbit, updates), to: Memelex.My.Wiki

  # A #TODO is any tidbit tagged with #TODO - there is always MetaData??

  # We should support #TODOs as maps, lists, or text - basically anything can be a #TODO

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
    %{params | tags: [tag]} |> new()
  end

  # TODO we need to incorporate something like priority, or due date

  def new(%{tags: tlist} = params) when is_list(tlist) do
    validate_tag_list!(tlist)

    params
    |> Map.merge(%{tags: tlist ++ [@tag]})
    |> Memelex.My.Wiki.new()
  end

  # this is a nice convenience function, make a TODO in one line
  def new(title) when is_bitstring(title) do
    new(%{title: title})
  end

  def new(params) do
    params
    |> Map.merge(%{tags: [@tag]})
    |> Memelex.My.Wiki.new()
  end

  # more convenient to use keyword lists on the CLI
  def new(title, tags: tlist) when is_bitstring(title) do
    new(%{title: title, tags: tlist})
  end

  # I have gone to type this a few times, so just make it available and call new/1 (this is a convenience API)
  def add(params) do
    new(params)
  end

  @doc ~s(Fetch the whole list of all TODOs)
  def all do
    {:ok, tidbits} = GenServer.call(WikiServer, :list_all_tidbits)
    Enum.filter(tidbits, &Enum.member?(&1.tags, @tag))
  end

  # this is just a shortcut/convenience function, mainly for use on the CLI
  def all(t: tag), do: all(tagged: tag)
  def all(tag: tag), do: all(tagged: tag)
  def all(tags: tag), do: all(tagged: tag)
  def all(tagged: tag), do: all(%{tags: [tag]})

  def all(%{tags: tag}) when is_bitstring(tag) do
    # make it a list with a single entry, but not a raw bitstring
    all(%{tags: [tag]})
  end

  def all(%{tags: [tag]}) when is_bitstring(tag) do
    all() |> Enum.filter(&Enum.member?(&1.tags, tag))
  end

  def list do
    all() |> Enum.map(& &1.title)
  end

  def list(filter_opts) do
    all(filter_opts) |> Enum.map(& &1.title)
  end

  def random do
    {:ok, tidbits} = GenServer.call(WikiServer, :list_all_tidbits)

    only_todos = fn tidbit -> tidbit.tags |> Enum.member?("#TODO") end

    tidbits
    |> Enum.filter(only_todos)
    |> Enum.random()
  end

  # use metadata
  def set_due_date(todo, %{due_date: datetime}) do
    raise "not implemented"
  end

  def set_reminder(todo, %{note: note, datetime: datetime}) do
    raise "not implemented"
  end

  def mark_complete(%{uuid: uuid}) do
    raise "can't mark TODOs as complete yet"
  end

  def validate_tag_list!([]) do
    true
  end

  def validate_tag_list!([tag | rest]) when is_bitstring(tag) do
    validate_tag_list!(rest)
  end

  # matches anything besides a string
  def validate_tag_list!([tag | _rest]) do
    context = %{invalid_tag: tag}
    raise "an invalid tag was passed in via the tag list. #{inspect(context)}"
  end
end

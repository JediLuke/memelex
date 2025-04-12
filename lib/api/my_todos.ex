defmodule Memelex.My.TODOs do
  # A #TODO is any tidbit tagged with #TODO - there is always MetaData??

  # We should support #TODOs as maps, lists, or text - basically anything can be a #TODO
  alias Memelex.WikiServer

  @tag "#TODO"
  def tag, do: @tag

  # just convenience API functions
  defdelegate find(search_term), to: Memelex.My.Wiki
  defdelegate update(tidbit, updates), to: Memelex.My.Wiki

  @in_progress "in_progress"
  @blocked "blocked"
  @done "done"
  @cancelled "cancelled"

  # This function should return/print some helpful advice for the user on how
  # to make a new TODO
  def new do
    ~s(To add a new TODO, all you need to provide is a title. Here's how to make a new TODO:

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
    # if push_gui_changes_too?() do
    # Memelex.Fluxus.event(:show_todos)
    # end
  end

  # I have gone to type this a few times, so just make it available and
  # call new/1 (this is a convenience API)
  def add(params) do
    new(params)
  end

  def add_action(%Memelex.TidBit{} = todo, action) when is_binary(action) do
    {:ok, todo_tidbit} = Memelex.My.Wiki.update(todo, %{add_action: action})
    todo_tidbit
  end

  def add_note(todo, note) do
    {:ok, todo_tidbit} = Memelex.My.Wiki.update(todo, %{data: todo.data <> "\n" <> note})
    todo_tidbit
  end

  # def note(%Memelex.TidBit{} = todo, note) when is_binary(note) do
  def note(note) when is_binary(note) do
    case current() do
      nil ->
        raise "could not add a note, no TODO selected"

      todo ->
        add_note(todo, note)
    end
  end

  def set_description(%Memelex.TidBit{} = todo, description) when is_binary(description) do
    {:ok, todo_tidbit} = Memelex.My.Wiki.update(todo, %{data: description})
    todo_tidbit
  end

  def append_description(%Memelex.TidBit{} = todo, description) when is_binary(description) do
    {:ok, todo_tidbit} = Memelex.My.Wiki.update(todo, %{data: todo.data <> "\n" <> description})
    todo_tidbit
  end

  def log(%Memelex.TidBit{} = todo, log) when is_binary(log) do
    # {:ok, todo_tidbit} = Memelex.My.Wiki.update(todo, %{append_to_history: log})
    {:ok, todo_tidbit} = Memelex.My.Wiki.rec_history(todo, log)

    todo_tidbit
  end

  # My.TODOs.current
  #

  def current, do: selected()

  # TODO - since this is reaching into the radix store, this doesn't
  # actually belong here - we should cast an event up to Flamelex
  # & bail out, since this function sort-of wouldn't make sense
  # if we were just running Memelex on its own in CLI

  # def selected do
  #   raise "TODO - since this is reaching into the radix store, this doesn't"
  #   Memelex.Fluxus.event(:show_todos)
  # end

  def selected do
    # call fluxus radix, look and see if we havew a selected todo & return it
    # {:ok, rdx_state} = GenServer.call(Flamelex.Fluxus.RadixStore, :get_state)

    # TODO this is a hack, we should be able to get the selected todo from the radix state
    # raise "re-jig this"
    # TODO actually a with statement might be elegant here
    case Flamelex.Fluxus.RadixStore.get() do
      %{
        layers: %{
          one: %{
            active_apps: [
              Flamelex.GUI.Component.TODOlist,
              Flamelex.GUI.Component.TODOdetails
            ]
          }
        },
        apps: %{
          # HERE
          # todo_details: %Memelex.TidBit{} = t
          # NOTE - trying to put these rigidly defines state structs here made me realise (cause it didnt compile lol)
          # that this code shouldn;t be here, we should throw an event instead. I'm haxing so I'm
          # gonna keep this function going for a bit but I need to comment out the state stuff
          # to get it to compile, but I'm gonna leave this here as a reminder to myself
          # todo_details: %Flamelex.GUI.Component.TODOdetails.State{tidbit: %Memelex.TidBit{} = t}
          todo_details: %{tidbit: %Memelex.TidBit{} = t}
        }
      } ->
        t

      otherwise ->
        raise "why you callin `selected TODO` on a state we don't code for???"
        # IO.inspect(otherwise)
        # nil
    end
  end

  def show do
    Memelex.Fluxus.event(:show_todos)
  end

  @doc ~s(Fetch the whole list of all TODOs)
  def all do
    # TODO don't use list_all & filter... do it inside WIkiServer
    {:ok, tidbits} = GenServer.call(WikiServer, :list_all_tidbits)
    Enum.filter(tidbits, &Enum.member?(&1.tags, @tag))
  end

  def all(:t) do
    all() |> Enum.map(& &1.title)
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

  # def all(filter: :priority) do
  #   all()
  #   # |> filter()
  #   # |> sort()
  #   # |> Enum.filter(fn
  #   #   %{meta: [%{"priority" => _p}]} ->
  #   #     true

  #   #   _else ->
  #   #     false
  #   # end)

  #   # filter_in_progress(list)
  #   # # TODO for now this works but priority is a terrible name because p1 implies highest priority to me,
  #   # # but this works by having bigger numbres mean more important
  #   # |> Enum.sort(fn %{meta: [%{"priority" => p1}]}, %{meta: [%{"priority" => p2}]} -> p1 >= p2 end)
  # end

  def all(filter: :cancelled) do
    all()
    |> Enum.filter(& &1.status == "cancelled")
  end

  def all(filter: :done) do
    all()
    |> Enum.filter(& &1.status == "done")
  end

  # def all(filter: :newest), do: all(filter: {:newest, 20})

  def all(filter: {:newest, x}) do
    all()
    # if t1 is newer or the same as t2, the result will not be :lt
    |> Enum.sort(fn %{created: t1}, %{created: t2} ->
      # TODO shouldnt we do this when we take the TODO out of the memex?
      t1 = make_datetype(t1)
      t2 = make_datetype(t2)

      DateTime.compare(t1, t2) != :lt
    end)
    |> Enum.take(x)
  end

  # def all(filter: :oldest), do: all(filter: {:oldest, 20})

  def all(filter: {:oldest, x}) do
    all()
    # if t1 is older or the same as t2, the result will not be :gt
    |> Enum.sort(fn %{created: t1}, %{created: t2} ->
      # TODO shouldnt we do this when we take the TODO out of the memex?
      t1 = make_datetype(t1)
      t2 = make_datetype(t2)

      DateTime.compare(t1, t2) != :gt
    end)
    |> Enum.take(x)
  end

  def all(filter: :needs_triage) do
    all()
    |> Enum.filter(&is_nil(Memelex.TidBit.priority(&1)))
    |> Enum.reject(& &1.status == "done" or &1.status == "cancelled")
  end

  def all(filter: {:top_priority, n}) do
    all()
    |> Enum.reject(&is_nil(Memelex.TidBit.priority(&1)))
    |> Enum.sort(fn t1, t2 ->
      # we want to sort it so that items with "lower" priority are actually higher, priority 1 is higher than priority 10
      Memelex.TidBit.priority(t2) >= Memelex.TidBit.priority(t1)
    end)
    # TODO sort by due date somehow, rank them on how close the due date is
    # TODO somehow rank them by impact, what would it mean if I don't do this
    |> Enum.reject(& &1.status == "done" or &1.status == "cancelled")
    |> Enum.take(n)
  end

  # def all(filter: :cancelled) do
  #   all()
  #   |> Enum.filter(fn
  #     # %{status: "cancelled"} ->
  #     %{status: @cancelled} ->
  #       true

  #     _else ->
  #       false
  #   end)
  # end

  def all(filter: {:random, x}) do
    Enum.take_random(all(), x)
  end

  # def all(filter: :un_prioritized) do
  #   all()
  #   |> Enum.filter(fn
  #     %{meta: [%{"priority" => _p}]} ->
  #       false

  #     _else ->
  #       true
  #   end)

  #   filter_in_progress(list)
  # end

  # this one is a little weird, it exists because there's some dropdowns which
  # have a bunch of possible filters and one of those filters is "all", they're
  # gonna use this function with this syntax so we need to include a special
  # one for "all" to keep that working
  # def all(filter: nil) do
  #   all()
  # end

  def all(filter: :all) do
    all()
  end

  def all(filter: :overdue) do
    all()
    |> filter(:action_date_passed)
    |> Enum.reject(& &1.status == "done")
    |> Enum.reject(& &1.status == "cancelled")

    # |> filter(:in_progress)
  end

  def all(filter: :this_week) do
    all()
    |> filter(:this_week)
  end

  def all(filter: :this_month) do
    all()
    |> filter(:this_month)
  end

  # def all(filter: unknown_filter) do
  #   IO.puts("NO FILTER FOUND FOR #{inspect(unknown_filter)}")
  #   all()
  # end

  # def all(filter: f) do
  #   filter(all(), f)
  # end

  # def filter_in_progress(list) do
  #   list
  #   |> Enum.filter(fn
  #     %{status: s} when s in @not_in_progress ->
  #       false

  #     _else ->
  #       true
  #   end)
  # end

  # all()
  # |> Enum.filter(fn
  #   %{meta: [%{"due_date" => %{"date" => due_date}}]} ->
  #     due_date < Date.utc_today()

  #   %{meta: [%{"due_date" => no_match}]} ->
  #     # this clause catches situations where I have put a type of due date in the memex that this function doesn't recognise :P
  #     raise "due_date not recognised: #{inspect(no_match)}"

  #   %{meta: [%{"planned_date" => pd}]} when is_binary(pd) ->
  #     {:ok, pd_date} = Date.from_iso8601(pd)
  #     pd_date < Date.utc_today()

  #   %{meta: [%{"planned_date" => %Date{} = pd}]} ->
  #     pd < Date.utc_today()

  #   %{
  #     meta: [
  #       %{
  #         "planned_date" => %{"the_week_beginning_on" => planned_week_start}
  #       }
  #     ]
  #   } ->
  #     # today = Date.utc_today()
  #     # start_of_week = Date.beginning_of_week(today, :sunday)
  #     # end_of_week = Date.end_of_week(today, :sunday)

  #     week_start_date =
  #       if is_binary(planned_week_start) do
  #         {:ok, week_start_as_date} = Date.from_iso8601(planned_week_start)
  #         week_start_as_date
  #       else
  #         planned_week_start
  #       end

  #     end_of_week = Date.end_of_week(week_start_date, :sunday)

  #     end_of_week < Date.utc_today()

  #   %{meta: [%{"planned_date" => no_match}]} ->
  #     # this clause catches situations where I have put a type of due date in the memex that this function doesn't recognise :P
  #     raise "planned_date not recognised: #{inspect(no_match)}"

  #   _otherwise ->
  #     false
  # end)

  # def all(filter: :overdue) do
  #   all()
  #   |> Enum.filter(fn
  #     %{meta: [%{"due_date" => %{"date" => due_date}}]} ->
  #       due_date < Date.utc_today()

  #     %{meta: [%{"due_date" => no_match}]} ->
  #       # this clause catches situations where I have put a type of due date in the memex that this function doesn't recognise :P
  #       raise "due_date not recognised: #{inspect(no_match)}"

  #     %{meta: [%{"planned_date" => pd}]} when is_binary(pd) ->
  #       {:ok, pd_date} = Date.from_iso8601(pd)
  #       pd_date < Date.utc_today()

  #     %{meta: [%{"planned_date" => %Date{} = pd}]} ->
  #       pd < Date.utc_today()

  #     %{
  #       meta: [
  #         %{
  #           "planned_date" => %{"the_week_beginning_on" => planned_week_start}
  #         }
  #       ]
  #     } ->
  #       # today = Date.utc_today()
  #       # start_of_week = Date.beginning_of_week(today, :sunday)
  #       # end_of_week = Date.end_of_week(today, :sunday)

  #       week_start_date =
  #         if is_binary(planned_week_start) do
  #           {:ok, week_start_as_date} = Date.from_iso8601(planned_week_start)
  #           week_start_as_date
  #         else
  #           planned_week_start
  #         end

  #       end_of_week = Date.end_of_week(week_start_date, :sunday)

  #       end_of_week < Date.utc_today()

  #     %{meta: [%{"planned_date" => no_match}]} ->
  #       # this clause catches situations where I have put a type of due date in the memex that this function doesn't recognise :P
  #       raise "planned_date not recognised: #{inspect(no_match)}"

  #     _otherwise ->
  #       false
  #   end)
  # end

  @in_progress [@in_progress, @blocked]
  @not_in_progress [@cancelled, @done]

  def filter(list, :in_progress) do
    list
    |> Enum.filter(fn
      # %{status: s} when s in @in_progress ->
      #   true

      # TODO this should really be an inclusive search because we should set thigns to "in_progress" when they get assigned or whatever, but up until now we haven't been assigning things that way and in-progress doesnt mean what it should, so I have to do this exclusive search until that gets fixed
      %{status: s} when s in @not_in_progress ->
        false

      _else ->
        true
    end)
  end

  def filter(list, :this_week) do
    this_week = Memelex.My.Calendar.this_week()

    list
    |> Enum.filter(fn
      %{meta: [%{"due_date" => due_date}]} ->
        due_date = make_datetype(due_date)

        due_date >= this_week.start() and
          due_date <= this_week.end()

      %{meta: [%{"planned_date" => %{"the_week_beginning_on" => week_start}}]} ->
        plnd_date = make_datetype(week_start)

        plnd_date >= this_week.start() and
          plnd_date <= this_week.end()

      %{meta: [%{"planned_date" => plnd_date}]} ->
        plnd_date = make_datetype(plnd_date)

        plnd_date >= this_week.start() and
          plnd_date <= this_week.end()

      _otherwise ->
        false
    end)
  end

  def filter(list, :this_month) do
    this_month = Memelex.My.Calendar.this_month()

    list
    |> Enum.filter(fn
      %{meta: [%{"due_date" => due_date}]} ->
        due_date = make_datetype(due_date)

        due_date >= this_month.start() and
          due_date <= this_month.end()

      %{meta: [%{"planned_date" => %{"the_week_beginning_on" => week_start}}]} ->
        plnd_date = make_datetype(week_start)

        plnd_date >= this_month.start() and
          plnd_date <= this_month.end()

      %{meta: [%{"planned_date" => plnd_date}]} ->
        plnd_date = make_datetype(plnd_date)

        plnd_date >= this_month.start() and
          plnd_date <= this_month.end()

      _otherwise ->
        false
    end)
  end

  def filter(list, :next_month) do
    next_month = Memelex.My.Calendar.next_month()

    list
    |> Enum.filter(fn
      %{meta: [%{"due_date" => due_date}]} ->
        due_date = make_datetype(due_date)

        due_date >= next_month.start() and
          due_date <= next_month.end()

      %{meta: [%{"planned_date" => %{"the_week_beginning_on" => week_start}}]} ->
        plnd_date = make_datetype(week_start)

        plnd_date >= next_month.start() and
          plnd_date <= next_month.end()

      %{meta: [%{"planned_date" => plnd_date}]} ->
        plnd_date = make_datetype(plnd_date)

        plnd_date >= next_month.start() and
          plnd_date <= next_month.end()

      _otherwise ->
        false
    end)
  end

  def filter(list, :action_date_passed) do
    today = Memelex.My.Calendar.today()

    list
    |> Enum.filter(&action_date_passed?/1)
  end

  def action_date_passed?(%Memelex.TidBit{} = todo) do
    today = Memelex.My.Calendar.today()

    case todo do
      %{meta: [%{"due_date" => due_date}]} ->
        due_date = make_datetype(due_date)
        # due_date < today
        Date.compare(due_date, today) == :lt

      %{meta: [%{"planned_date" => %{"the_week_beginning_on" => plnd_date}}]} ->
        plnd_date = make_datetype(plnd_date)
        this_week = Memelex.My.Calendar.this_week()
        # IO.inspect(plnd_date)
        # IO.inspect(this_week.start())
        # plnd_date < this_week.start()
        Date.compare(plnd_date, this_week.start()) == :lt

      %{meta: [%{"planned_date" => plnd_date}]} ->
        plnd_date = make_datetype(plnd_date)
        # plnd_date < today
        Date.compare(plnd_date, today) == :lt

      _otherwise ->
        # IO.puts("no due date or planned date found")
        false
    end
  end

  # temp hack
  # def all(filter: _f) do
  #   all()
  # end

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

  def set_planned_date(%Memelex.TidBit{} = todo, %Date{} = date) do
    {:ok, updated_todo} = Memelex.My.Wiki.update(todo, %{"planned_date" => date})
    updated_todo
  end

  def schedule_this_week(%Memelex.TidBit{} = todo) do
    # def schedule_this_week() do
    today = Date.utc_today()
    # Assuming the week starts on Sunday
    start_of_week = Date.beginning_of_week(today, :sunday)

    {:ok, updated_todo} =
      Memelex.My.Wiki.update(todo, %{
        "planned_date" => %{"the_week_beginning_on" => start_of_week}
      })

    updated_todo
  end

  # use metadata
  # def add_due_date(todo, %{due_date: %Date{} = due_date}) do
  #   {:ok, updated_todo} = Memelex.My.Wiki.update(todo, %{"due_date" => due_date})
  #   updated_todo
  # end

  def set_due_date(todo, %Date{} = due_date) do
    {:ok, updated_todo} = Memelex.My.Wiki.update(todo, %{"due_date" => due_date})
    updated_todo
  end

  @valid_statuses [@in_progress, @blocked, @done, @cancelled]
  def set_status(%Memelex.TidBit{} = todo, status) when status in @valid_statuses do
    {:ok, updated_todo} = Memelex.My.Wiki.update(todo, %{"status" => status})
    updated_todo
  end

  def set_status(%Memelex.TidBit{} = todo, status) do
    # {:ok, updated_todo} = Memelex.My.Wiki.update(todo, %{"status" => status})
    # updated_todo

      IO.inspect(status, label: "BUNK STATUS???")
      todo
  end

  def set_priority(%Memelex.TidBit{} = todo, p) when is_integer(p) and p >= 1 do
    {:ok, updated_todo} = Memelex.My.Wiki.update(todo, %{"priority" => p})
    updated_todo
  end

  # def set_reminder(todo, %{note: note, datetime: datetime}) do
  #   raise "not implemented"
  # end

  def mark_complete(%Memelex.TidBit{} = todo) do
    set_status(todo, @done)
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

  # maybe this is a hack/smell but it takes in a "planned date" and makes it a datetime so the contract is good...
  # def make_datetype(%{"the_week_beginning_on" => week_start}) do
  #   make_datetype(week_start)
  # end

  def make_datetype(%Date{} = d), do: d

  # TODO this feels like hacking around something that ought not exist!?!? Why are we having different datetime strings in different places??
  def make_datetype(date) when is_binary(date) do
    case DateTime.from_iso8601(date) do
      {:ok, d_datetime, _offset} ->
        d_datetime

      {:error, _reason} ->
        # Try parsing as a Date
        case Date.from_iso8601(date) do
          {:ok, d_date} ->
            # Convert Date to DateTime for consistency
            # DateTime.new!(parsed_date, ~T[00:00:00], "Etc/UTC")
            d_date

          {:error, _reason} ->
            raise ArgumentError, "Invalid date format"
        end
    end
  end
end

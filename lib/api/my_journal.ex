defmodule Memex.My.Journal do
  alias Memex.Env.WikiManager

  @doc ~s(Opens today's Journal entry, with a fresh timestamp appended.)
  def now do
    now = Memex.My.current_time()

    #{:ok, todays_entry} =
    #  find_entry(now) |> TidBit.append(journal_timestamp(now)) #TODO and update modified time
    
    raise "now use gedit or whatever to open todays entry"
    #System.cmd("gedit #{}")
  end

  @doc ~s(Open today's Journal entry.)
  def today() do
    {:ok, t} = Memex.My.current_time() |> find_entry()
    {"", 0} = System.cmd("gedit", [t.data.filepath]) #TODO need to do this in a different process?? This has the issue of locking up my IEx shell while gedit is open (encourages me to save & close the journal I guess...)
    :ok
  end

  def yesterday do
    {:ok, t} = find_relative_page_tidbit(-1) # negative values move backwards in time
    open_entry(t)
  end

  def tomorrow do
    {:ok, t} = find_relative_page_tidbit(1) # one page forward in the journal
    open_entry(t)
  end

  def open_relative_entry(x) when is_integer(x) do
    {:ok, t} = find_relative_page_tidbit(x)
    open_entry(t)
  end

  @doc ~s(Open a Journal entry relative to today, e.g. open the entry for 3 days from now.)
  def find_relative_page_tidbit(x) when is_integer(x) do
    one_day = 24*60*60 # number of seconds in 24 hours
    
    Memex.My.current_time()
    |> DateTime.add(x*one_day, :second)
    |> find_entry()
  end

  # either finds, or creates, the TidBit & text file for a Journal entry
  def find_entry(datetime) do

    tidbit_title = journal_page_title(datetime)

    {:ok, tidbits} =
      WikiManager |> GenServer.call(:can_i_get_a_list_of_all_tidbits_plz)

    # look for todays journal entry in the Wiki
    # e.g. tagged "my_journal" & title is "Journal of JediLuke ~ Wednesday 29th of June, 2021")
    find_todays_journal_entry =
      fn(tidbit) ->
        (tidbit.title == tidbit_title) and (tidbit.tags |> Enum.member?("my_journal"))
      end

    case tidbits |> Enum.filter(find_todays_journal_entry) do
      [todays_tidbit = %Memex.TidBit{}] ->
        {:ok, todays_tidbit}
      _else ->
        new_journal_tidbit(datetime)
    end
  end

  @doc ~s(Makes a new Journal TidBit for a datetime, including the file for the entry itself.)
  def new_journal_tidbit(datetime) do
    Memex.My.Wiki.new_tidbit(%{
      title: journal_page_title(datetime),
      type: {:external, :textfile},
      tags: ["my_journal"],
      data: {:filepath, journal_entry_filepath(datetime)}
    })
  end

  @doc ~s(Contruct a title string for my Journal for a given datetime.)
  def journal_page_title(datetime) do
    "Journal of #{Memex.My.nickname()} ~ #{day_and_month(datetime)}, #{datetime.year |> Integer.to_string()}"
  end

  @doc ~s(Return a string containing the day of the month in long-form.)
  def day_and_month(datetime) do
    day_of_the_week =
      datetime |> DateTime.to_date() |> Date.day_of_week() |> day_name()
    month_name = 
      datetime.month |> month_name() # e.g. July or August
    day_of_the_month =
      datetime.day |> pad_to_double_digit_string() # e.g. "01", "02" or "29"

    # e.g. 'Wednesday 29 of June'
    "#{day_of_the_week} #{day_of_the_month} of #{month_name}"
  end

  @doc ~s(Return the filepath for the Journal entry for a specific DateTime. If it doesn't exist yet, then create it.)
  def journal_entry_filepath(datetime) do

    # we save Journal files in a structure, `memex/environment/journal/year/month/xx-day.txt`
    journal_directory =
      memex_directory()
      |> Path.join("/journal")
      |> Path.join("/#{datetime.year  |> Integer.to_string()}")
      |> Path.join("/#{datetime.month |> month_name()}")

    if not File.exists?(journal_directory) do
      File.mkdir_p(journal_directory)
    end

    {day_of_the_week_abbreviation, _rest} =
      datetime |> DateTime.to_date() |> Date.day_of_week() |> day_name() |> String.split_at(3)
    day_of_the_month =
      datetime.day |> pad_to_double_digit_string() # e.g. "01", "02" or "29"
    filename = "#{day_of_the_month}-#{day_of_the_week_abbreviation}.txt"

    journal_entry_file =
      journal_directory |> Path.join("/#{filename}")

    # make a new text file if one hasn't been created yet
    if not File.exists?(journal_entry_file) do
      {:ok, file} = File.open(journal_entry_file, [:write])
      IO.binwrite(file, journal_page_title(datetime) <> "\n\n")
      File.close(file)
    end
      
    journal_entry_file
  end

  def open_entry(%{data: %{filepath: page}}) when is_bitstring(page) do
    {"", 0} = System.cmd("gedit", [page]) #TODO need to do this in a different process?? This has the issue of locking up my IEx shell while gedit is open (encourages me to save & close the journal I guess...)
    :ok
  end

  def memex_directory do
    {:ok, dir} = WikiManager |> GenServer.call(:whats_the_current_memex_directory?)
    dir
  end

  # turn an integer 'day of the month' into a string which is always double-digit
  def pad_to_double_digit_string(x) when x in [1,2,3,4,5,6,7,8,9] do
    "0" <> Integer.to_string(x)
  end
  def pad_to_double_digit_string(x) when is_integer(x) and x > 9 and x <= 31 do # max 31 days in a month or week
    Integer.to_string(x)
  end

  # used to compute the title for today's Journal entry
  def day_name(1), do: "Monday"
  def day_name(2), do: "Tuesday"
  def day_name(3), do: "Wednesday"
  def day_name(4), do: "Thursday"
  def day_name(5), do: "Friday"
  def day_name(6), do: "Saturday"
  def day_name(7), do: "Sunday"

  # used to compute the title for today's Journal entry
  def month_name(1), do: "January"
  def month_name(2), do: "February"
  def month_name(3), do: "March"
  def month_name(4), do: "April"
  def month_name(5), do: "May"
  def month_name(6), do: "June"
  def month_name(7), do: "July"
  def month_name(8), do: "August"
  def month_name(9), do: "September"
  def month_name(10), do: "October"
  def month_name(11), do: "November"
  def month_name(12), do: "December"
 
end
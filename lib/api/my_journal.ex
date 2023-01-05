defmodule Memelex.My.Journal do
  alias Memelex.Env.WikiManager
  alias Memelex.Facts.GregorianCalendar
  alias Memelex.Utils.StringifyDateTimes
  require Logger

  @doc ~s(Opens today's Journal entry, with a fresh timestamp appended.)
  def now do
    now = Memelex.My.current_time()
    {:ok, t} = now |> find_entry()
    Logger.warn "#TODO we should be appending a timestamp here..."
    #TidBit.append(t, journal_timestamp(now)) #TODO and update modified time
    open(t)
  end

  @doc ~s(Open today's Journal entry.)
  def today() do
    {:ok, t} = Memelex.My.current_time() |> find_entry()
    open(t)
  end

  def yesterday do
    {:ok, t} = find_relative_page_tidbit(-1) # negative values move backwards in time
    open(t)
  end

  def tomorrow do
    {:ok, t} = find_relative_page_tidbit(1) # one page forward in the journal
    open(t)
  end

  def open_relative_entry(x) when is_integer(x) do
    {:ok, t} = find_relative_page_tidbit(x)
    open(t)
  end

  @doc ~s(Open a Journal entry relative to today, e.g. open the entry for 3 days ago with `-3`.)
  def find_relative_page_tidbit(x) when is_integer(x) do
    one_day = 24*60*60 # number of seconds in 24 hours
    
    Memelex.My.current_time()
    |> DateTime.add(x*one_day, :second)
    |> find_entry()
  end

  # either finds, or creates, the TidBit & text file for a Journal entry
  def find_entry(datetime) do

    tidbit_title = journal_page_title(datetime)

    {:ok, tidbits} =
      WikiManager |> GenServer.call(:list_all_tidbits)

    # look for todays journal entry in the Wiki
    # e.g. tagged "my_journal" & title is "Journal of JediLuke ~ Wednesday 29th of June, 2021")
    find_todays_journal_entry =
      fn(tidbit) ->
        (tidbit.title == tidbit_title) and (tidbit.tags |> Enum.member?("my_journal"))
      end

    case tidbits |> Enum.filter(find_todays_journal_entry) do
      [todays_tidbit = %Memelex.TidBit{}] ->
        {:ok, todays_tidbit}
      _else ->
        new_journal_tidbit(datetime)
    end
  end

  @doc ~s(Makes a new Journal TidBit for a datetime, including the file for the entry itself.)
  def new_journal_tidbit(datetime) do
    new_title = journal_page_title(datetime)
    Logger.info "creating new Journal entry `#{new_title}`..."
    Memelex.TidBit.construct(%{
      title: new_title,
      type: {:external, :textfile},
      tags: ["my_journal"],
      data: {:filepath, journal_entry_filepath(datetime)}
    })
    |> Memelex.My.Wiki.new_tidbit()
  end

  @doc ~s(Contruct a title string for my Journal for a given datetime.)
  def journal_page_title(datetime) do
    day_and_month =
      datetime |> StringifyDateTimes.format("day_xx_of_month")
    year =
      datetime |> StringifyDateTimes.format("year_as_XXXX")

    "Journal of #{Memelex.My.nickname()} ~ #{day_and_month}, #{year}"
  end


  @doc ~s(Return the filepath for the Journal entry for a specific DateTime. If it doesn't exist yet, then create it.)
  def journal_entry_filepath(datetime) do

    # we save Journal files in a structure, `memex/environment/journal/year/month/xx-day.txt`
    journal_directory =
      Memelex.Utils.ToolBag.memex_directory()
      |> Path.join("/journal")
      |> Path.join("/#{datetime.year |> Integer.to_string()}")
      |> Path.join("/#{datetime.month |> GregorianCalendar.month_name()}")

    if not File.exists?(journal_directory) do
      File.mkdir_p(journal_directory)
    end

    filename =
      StringifyDateTimes.format(datetime, :journal_format) <> ".txt" # e.g. "23-Fri.txt"

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

  # this is here so that if we use something like Journal.find,
  # which returns an ok tuple, we can pipe right into Journal.open
  def open({:ok, params}) do
    open(params)
  end

  #NOTE: Filter on both atom and String keys here (why?)
  def open(%{data: %{filepath: page}}) when is_bitstring(page) do
    Memelex.Utils.ToolBag.open_external_textfile(page)
  end
  def open(%{data: %{"filepath" => page}}) when is_bitstring(page) do
    Memelex.Utils.ToolBag.open_external_textfile(page)
  end
end
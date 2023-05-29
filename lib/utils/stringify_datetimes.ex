defmodule Memelex.Utils.StringifyDateTimes do


  @doc """
  This function takes in a %DateTime{} and converts it to a consistent
  string format. This is needed for things like:
  - creating the name of today's Journal file
  - creating the filename for Memex backups
  - etc...

  e.g. 07-Thu
  """
  def format(datetime, :journal_format) do

    day_of_the_month =
      datetime.day |> pad_to_double_digit_string(max: 31) # e.g. "01", "02" or "29", max 31 days in a month or week

    {day_of_the_week_abbreviation, _rest} =
      datetime
      |> DateTime.to_date()
      |> Date.day_of_week()
      |> Memelex.Facts.GregorianCalendar.day_name()
      |> String.split_at(3)

    "#{day_of_the_month}-#{day_of_the_week_abbreviation}"
  end

  def format(datetime, "day_xx_of_month") do
    day_of_the_week  = datetime |> format("day_of_the_week")
    month_name       = datetime |> format("month_name")
    day_of_the_month = datetime |> format("day_of_the_month")

    # e.g. 'Wednesday 29 of June'
    "#{day_of_the_week} #{day_of_the_month} of #{month_name}"
  end

  def format(datetime, "XXmonYY-HH:mm") do
    day_of_the_month   = datetime |> format("day_of_the_month")
    tla_month_name     = datetime |> format("month_name") |> String.slice(0, 3)
    year               = datetime |> format("year_as_XXXX")
    twentyfour_hr_time = datetime |> format("24hr HH:mm")

    # e.g. '29jun,2023-19:23'
    #TODO use journal_format here
    "#{day_of_the_month}#{tla_month_name},#{year}-#{twentyfour_hr_time}"
  end

  def format(%{hour: h, minute: m} = _datetime,"24hr HH:mm") do
    pad_to_double_digit_string(h, max: 24) <> ":" <> pad_to_double_digit_string(m, max: 60)
  end

  def format(%{hour: h, minute: m} = _datetime, "24hr HH:mm") do
    pad_to_double_digit_string(h, max: 24) <> ":" <> pad_to_double_digit_string(m, max: 60)
  end

  def format(%{year: year}, "year_as_XXXX") when is_integer(year) do
    year |> Integer.to_string()
  end

  def format(datetime, "day_of_the_week") do
    datetime
    |> DateTime.to_date()
    |> Date.day_of_week()
    |> Memelex.Facts.GregorianCalendar.day_name()
  end

  def format(datetime, "month_name") do
    datetime.month |> Memelex.Facts.GregorianCalendar.month_name() # e.g. July or August
  end

  def format(datetime, "day_of_the_month") do
    datetime.day |> pad_to_double_digit_string(max: 31) # e.g. "01", "02" or "29"
  end

  def format(datetime,extract_format) do
    IO.puts "DEPRECATE ME don't use extract..."

    format(datetime, extract_format)
  end

  # turn an integer 'day of the month' into a string which is always double-digit
  def pad_to_double_digit_string(0), do: "00"
  def pad_to_double_digit_string("0"), do: "00"
  def pad_to_double_digit_string("00"), do: "00"

  def pad_to_double_digit_string(x) when x in [1,2,3,4,5,6,7,8,9] do
    "0" <> Integer.to_string(x)
  end
  def pad_to_double_digit_string(x) when x in ["1","2","3","4","5","6","7","8","9"] do
    "0" <> x
  end
  def pad_to_double_digit_string(x, max: max) when is_integer(x) and x >= 0 and x <= max do
    Integer.to_string(x)
  end

end

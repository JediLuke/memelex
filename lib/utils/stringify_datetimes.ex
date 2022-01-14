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
      datetime.day |> pad_to_double_digit_string() # e.g. "01", "02" or "29"

    {day_of_the_week_abbreviation, _rest} =
      datetime
      |> DateTime.to_date()
      |> Date.day_of_week()
      |> Memelex.Facts.GregorianCalendar.day_name()
      |> String.split_at(3)

    "#{day_of_the_month}-#{day_of_the_week_abbreviation}"
  end

  def format(datetime, "day_xx_of_month") do
    day_of_the_week  = datetime |> format(extract: "day_of_the_week")
    month_name       = datetime |> format(extract: "month_name")
    day_of_the_month = datetime |> format(extract: "day_of_the_month")

    # e.g. 'Wednesday 29 of June'
    "#{day_of_the_week} #{day_of_the_month} of #{month_name}"
  end

  def format(%{year: year}, "year_as_XXXX") when is_integer(year) do
    year |> Integer.to_string()
  end

  def format(datetime, extract: "day_of_the_week") do
    datetime
    |> DateTime.to_date()
    |> Date.day_of_week()
    |> Memelex.Facts.GregorianCalendar.day_name()
  end

  def format(datetime, extract: "month_name") do
    datetime.month |> Memelex.Facts.GregorianCalendar.month_name() # e.g. July or August
  end

  def format(datetime, extract: "day_of_the_month") do
    datetime.day |> pad_to_double_digit_string() # e.g. "01", "02" or "29"
  end

  # turn an integer 'day of the month' into a string which is always double-digit
  def pad_to_double_digit_string(x) when x in [1,2,3,4,5,6,7,8,9] do
    "0" <> Integer.to_string(x)
  end
  def pad_to_double_digit_string(x) when x in ["1","2","3","4","5","6","7","8","9"] do
    "0" <> x
  end
  def pad_to_double_digit_string(x) when is_integer(x) and x > 9 and x <= 31 do # max 31 days in a month or week
    Integer.to_string(x)
  end 

end

defmodule Memelex.My.Calendar do
  def today do
    # TODO use my current timezone here (but save everything in UTC or unix time)
    Date.utc_today()
  end

  def this_week do
    today = Date.utc_today()

    # Assuming the week starts on Sunday
    %{
      start: Date.beginning_of_week(today, :sunday),
      end: Date.end_of_week(today, :sunday)
    }
  end

  def this_month do
    today = Date.utc_today()

    %{
      start: Date.beginning_of_month(today),
      end: Date.end_of_month(today)
    }
  end

  def next_month do
    today = Date.utc_today() |> Timex.shift(months: 1)

    %{
      start: Date.beginning_of_month(today),
      end: Date.end_of_month(today)
    }
  end
end

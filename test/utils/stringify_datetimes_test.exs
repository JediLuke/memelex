defmodule Memelex.Utils.StringifyDateTimesTest do
  alias Memelex.Utils.StringifyDateTimes
  use ExUnit.Case

  @saturday_24th_July "2021-07-24T19:15:37.292416-05:00" # Memelex.My.current_time |> DateTime.to_iso8601()

  setup do
    {:ok, test_datetime, _offset} = @saturday_24th_July |> DateTime.from_iso8601()

    %{
      test_data: test_datetime
    }
  end

  test "journal format", %{test_data: datetime} do
    assert StringifyDateTimes.format(datetime, :journal_format) == "24-Sat"
  end
end
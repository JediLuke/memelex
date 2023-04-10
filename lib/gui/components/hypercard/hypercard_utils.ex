defmodule Memelex.GUI.Components.HyperCard.Utils do
    require Logger

    

    def human_formatted_date(date) do
		Logger.debug "parsing date: #{inspect date} into human readable format..."
		{:ok, date, 0} = DateTime.from_iso8601(date)
		#IO.inspect date
		day = case Date.day_of_week(date) do
				1 -> "Mon"
				2 -> "Tue"
				3 -> "Wed"
				4 -> "Thu"
				5 -> "Fri"
				6 -> "Sat"
				7 -> "Sun"
			end
		month = case date.month do
				1 -> "Jan"
				2 -> "Feb"
				3 -> "Mar"
				4 -> "Apr"
				5 -> "May"
				6 -> "Jun"
				7 -> "Jul"
				8 -> "Aug"
				9 -> "Sep"
				10 -> "Oct"
				11 -> "Nov"
				12 -> "Dec"
			end
		"#{day} #{date.day} #{month} #{date.year}"
	end

end
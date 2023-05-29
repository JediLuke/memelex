defmodule Memelex.Facts.GregorianCalendar do

  @months [
      :january,
      :february,
      :march,
      :april,
      :may,
      :june,
      :july,
      :august,
      :september,
      :october,
      :november,
      :december
  ]


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
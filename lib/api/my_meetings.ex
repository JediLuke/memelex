defmodule Memelex.My.Meetings do
  alias Memelex.WikiServer
  alias Memelex.Utils.TidBits.ConstructorLogic, as: TidBitUtils

  @my_meetings "my_meetings"

  def new(params) do
    params
    |> TidBitUtils.sanitize_conveniences()
    |> TidBitUtils.apply_tag(@my_meetings)
    |> Memelex.TidBit.construct()
    |> Memelex.My.Wiki.new()
  end

  # API sugar, I like to "record" meetings, or "take a record" ~ My.Meetings.record %{title: "Something"}
  def record(params) do
    new(params)
  end

  @doc ~s(Fetch the whole list of TODOs)
  def list do
    Memelex.My.Wiki.list()
    |> Enum.filter(fn(tidbit) -> tidbit.type |> Enum.member?(@my_meetings) end)
  end

end
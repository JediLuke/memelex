defmodule Memex.My do
  require Logger

  def current_time do
    Logger.warn "We aren't checking the TimeZone in the Memex!!"
    #DateTime.now!("America/Chicago") #TODO update to elixir v1.12
    DateTime.utc_now()
  end

  def nickname do #TODO this should go find it in a real TidBit!
    "JediLuke"
  end

  #def timezone do
  #  tx |> DateTime.now!()
  #end

  def find_info_tiddler do
    raise "the idea is, all my info is in one tiddler, which is a map"
  end

  @doc ~s|A nice API, My.todos()|
  def todos do
    Memex.My.TODOs.list()
  end
end
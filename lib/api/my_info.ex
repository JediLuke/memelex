defmodule Memelex.My do
  require Logger

  #TODO so, this should be calling ExecMgr, which opens whoami.txt...

  def current_time do
    timezone() |> DateTime.now!()
  end

  def nickname do
    "JediLuke" #TODO this should go find it in a real TidBit!
  end

  def timezone do
    "America/Chicago" #TODO get timezone from Memex
  end

  def find_info_tiddler do
    raise "the idea is, all my info is in one tiddler, which is a map"
  end

  @doc ~s|A nice API, My.todos()|
  def todos do
    Memelex.My.TODOs.list()
  end
end
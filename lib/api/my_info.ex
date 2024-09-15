# TODO get each persons custom module to import these functions, e.g. JediLuke.current_time()
defmodule Memelex.My do
  require Logger

  # TODO so, this should be calling ExecMgr, which opens whoami.txt...

  def current_time do
    timezone() |> DateTime.now!()
  end

  def nickname do
    # TODO this should go find it in a real TidBit!
    "JediLuke"
  end

  def timezone do
    # TODO get timezone from Memex
    "America/Chicago"
  end

  def find_info_tiddler do
    raise "the idea is, all my info is in one tiddler, which is a map"
  end

  # @doc ~s|A nice API, My.todos()|
  # def todos do
  #   Memelex.My.TODOs.list()
  # end
end

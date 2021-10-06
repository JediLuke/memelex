defmodule Memex.Utils.Sync do
  @moduledoc """
  Sync the Memex across multiple devices.
  """
  require Logger

  def push do

    # copy the Memex
    memex_dir = Memex.Utils.ToolBag.memex_directory()
    dir_name = memex_dir |> Path.basename()
    {:ok, files_and_dirs} = File.cp_r(memex_dir, memex_dir <> "/../#{dir_name}_sync")

    # encrypt each file in the `sync` directory
    for filepath <- files_and_dirs do
      Memex.Utils.Encryption.encrypt_file(filepath, secret_key())
    end
    
    # commit any changes to the repo

    # push it up to a git repo

    # Actually, if each file was encrypted... we couldn't need to copy it!
  end

  defp secret_key do
    case System.get_env("MEMEX_SYNCING_KEY") do
      nil -> raise "need to set `MEMEX_SYNCING_KEY` as environment variable"
      key -> key
    end
  end


end
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

  def pull_in do

    # copy the encrypted files in the git repo into the Memex directory
    memex_dir = Memex.Utils.ToolBag.memex_directory()
    dir_name = memex_dir |> Path.basename()
    {:ok, files_and_dirs} = File.cp_r(memex_dir <> "/../#{dir_name}_sync", memex_dir)

    # delete the .git directory & contents because it breaks everything,
    # plus we dont really want this in our Memex anyway
    File.rm_rf!(memex_dir <> "/.git")
    files_and_dirs = # remove all git files from our list so we don't try to decrypt non-existing files
      files_and_dirs |> Enum.filter(& not String.contains?(&1, ".git"))
    IO.inspect files_and_dirs

    # decrypt all the files in the Memex directory
    for filepath <- files_and_dirs do
      Memex.Utils.Encryption.decrypt_file(filepath, secret_key())
    end
    
  end

  defp secret_key do
    case System.get_env("MEMEX_SYNCING_KEY") do
      nil -> raise "need to set `MEMEX_SYNCING_KEY` as environment variable"
      key -> key
    end
  end


end
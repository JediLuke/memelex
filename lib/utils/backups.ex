defmodule Memex.Utils.Backups do
  @moduledoc """
  Utilities for managing Memex backups.
  """
  alias Memex.Env.WikiManager


  def backup(:now) do
    System.cmd("cp", ["-r", memex_directory(), backups_directory()])
    IO.puts "backup complete."
  end

  def backup(:now, :cloud) do
    raise "can't back up to the could yet"
  end

  def memex_directory do
    {:ok, dir} = WikiManager |> GenServer.call(:whats_the_current_memex_directory?)
    dir
  end

  def backups_directory do
    {:ok, dir} = WikiManager |> GenServer.call(:whats_the_current_backups_directory?)
    dir
  end
end
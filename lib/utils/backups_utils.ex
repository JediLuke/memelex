defmodule Memelex.Utils.Backups do
  @moduledoc """
  Utilities for managing Memex backups.
  """
  alias Memelex.Env.WikiManager
  require Logger

  def perform_backup_procedure() do
    # pre-flight check
    with {:ok, backups_dir} <- GenServer.call(WikiManager, :whats_the_current_backups_directory?),
                       true <- File.exists?(backups_dir)
              do
                perform_backup_procedure(:all_systems_go, backups_dir)
              else
                error -> 
                  {:error, "Could not find the backups directory"}
              end 
    # if File.exists?(backups_directory()) do
    #   perform_backup_procedure(:all_systems_go, backups_directory)
    # else
    #   {:error, "Could not find the backups directory"}
    # end
  end

  def perform_backup_procedure(:all_systems_go, backups_dir) do
    now = Memelex.My.current_time()

    memex_directory =
      Memelex.Utils.ToolBag.memex_directory() #TODO this is probably a hell-dumb way of doing this...

    this_backup =
      case fetch_backup_records() do
             [] -> Memelex.BackupRecord.construct(%{
                     version: "1",
                     date: now
                   })
        records -> last_backup = hd(records)
                   Memelex.BackupRecord.construct(%{
                     version: last_backup.version |> increment_version(),
                     date: now
                   })
      end
    
    this_backup_dir = backups_dir
    |> Path.join("/backups")
    |> Path.join("/#{now.year |> Integer.to_string()}")
    |> Path.join("/#{Memelex.Facts.GregorianCalendar.month_name(now.month)}")
    |> Path.join("/backup#{this_backup.version}")

    if File.exists?(this_backup_dir <> "/backup_record.json") do
      raise "attempting to overwrite an existing backup!"
    end

    File.mkdir_p(this_backup_dir)
    System.cmd("cp", ["-r", memex_directory, this_backup_dir])

    #TODO hash the backup & save it in the BackupRecord

    Memelex.Utils.Backups.save_backup_metadata(this_backup, this_backup_dir)
    Memelex.Utils.Backups.append_to_record(this_backup)
    
    IO.puts "backup complete."
    :backup_successful
  end

  def perform_backup_procedure(:cloud) do
    #TODO do a GitHub backup
    raise "can't back up to the cloud yet"
  end

  def fetch_last_backup do
    case fetch_backup_records() do
      [last_backup|_rest] ->
          last_backup
      _otherwise ->
          :no_backups_found
    end
  end

  def fetch_backup_records do
    backup_records_file()
    |> Memelex.Utils.FileIO.read_maplist()
    |> sort_records(:descending_chronologically)
  end

  def sort_records(records_list, :descending_chronologically) do
    records_list
    |> Enum.sort(fn(a,b) -> a.timepoint >= b.timepoint end)
  end

  # save a file with a single %BackupRecord within each backup we make
  def save_backup_metadata(backup_record, backup_dir) do
    backup_dir <> "/backup_record.json"
    |> Memelex.Utils.FileIO.write_maplist([backup_record])
  end

  def append_to_record(backup_record) do
    new_backups_record =
      fetch_backup_records()
      |> Enum.concat([backup_record])

    backup_records_file()
    |> Memelex.Utils.FileIO.write_maplist(new_backups_record)
  end

  def backup_records_file do
    {:ok, dir} = WikiManager |> GenServer.call(:whats_the_current_memex_directory?)
    dir <> "/backups.json"
  end

  # def backups_directory do
  #   {:ok, dir} = WikiManager |> GenServer.call(:whats_the_current_backups_directory?)
  #   if not is_bitstring(dir) do #TODO check here that we do have a backup sdirectory (better than this!)
  #     raise "looks like there's no backups directory"
  #   else
  #     dir
  #   end

  #   case GenServer.call(WikiManager, :whats_the_current_backups_directory?) do
  #     {:ok, dir} when is_bitstring(dir) -> dir
  #     {:error, _reason} ->
  #   end
  # end

  defp increment_version(x) when is_bitstring(x) do
    add_one = fn(a) -> a + 1 end
    x |> String.to_integer() |> add_one.() |> Integer.to_string()
  end


end
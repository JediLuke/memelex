defmodule Memex.Agents.BackupManager do
  use GenServer
  require Logger
  alias Memex.Utils


  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  def init(_params) do
    Logger.info "#{__MODULE__} initializing..."

    init_state = %{
      #NOTE: this is just a simple list, of some of the concerns a BackupManager may face in their day to day job...
      concerns: [
        "keeping an up to date, reproducible & recoverable record of the memex",
        "syncing with memex code with the mainline in github",
        "checking the capability (memory/capacity/contracts/etc) of the backup volumes",
        "we need a way of periodically testing the validity, & robustness, of our backups",
        "every time we make a new password, it should trigger a backup"
      ]
    }

    GenServer.cast(self(), :perform_backups_status_check)

    {:ok, init_state}
  end

  def handle_cast(:perform_backups_status_check, state) do
    case Memex.Utils.Backups.fetch_last_backup() do
      :no_backups_found ->
         schedule(:commence_backup_procedures, :one_hour_from_now)
         {:noreply, state}
      last_backup = %Memex.BackupRecord{} ->
         analyze_last_backup(last_backup)
         {:noreply, state}
    end
  end

  def handle_info(:commence_backup_procedures, state) do
    #TODO BackupManager might need to talk to all other Agents which read/write from disk, and ask them not to do it until the backup is complete...
    IO.puts "LaLaLa backups manmager SHOULD BE IN CHARGE HERE@@@!!!"
    Memex.Utils.Backups.perform_backup_procedure()
    {:noreply, state}
  end

  def analyze_last_backup(b) do
    IO.inspect b, label: "WE FOUND A BACKUP TO ANALYZE"
  end

  def schedule(:commence_backup_procedures, :one_hour_from_now) do
    #raise "not working yet"
    IO.puts "THIS SHOULD SCHEDULE ONE HOUR FORM NOW ANOTHER BACKPPPP"
    #Process.send_after(self(), :commence_backup_procedures, :timer.hour(1)) # or whatever...
  end

end
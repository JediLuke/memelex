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

    {:ok, init_state, {:continue, :create_backups_record}}
  end

  def handle_continue(:create_backups_record, state) do
    # first, make a new backups record, if there isn't one already in existence
    if new_backup_file_creation_required?() do
      Logger.warn "could not find a BackupRecord file for this environment. Creating one now..."
      {:ok, file} = File.open(Memex.Utils.Backups.backup_records_file(), [:write])
      IO.binwrite(file, [] |> Jason.encode!)
      File.close(file)
    end
    {:noreply, state}
  end

  def new_backup_file_creation_required? do
    not File.exists?(Memex.Utils.Backups.backup_records_file())
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
    Logger.info "#{__MODULE__} commencing backup procedures..."
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
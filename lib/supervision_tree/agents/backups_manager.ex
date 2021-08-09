defmodule Memex.Agents.BackupManager do
  use GenServer
  require Logger
  alias Memex.Utils

  @status_check_period :timer.minutes(125)
  @autobackup_period_hours 24 # take auto backups daily 

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

    Process.send_after(self(), :perform_periodic_check, :timer.minutes(1))

    {:ok, init_state, {:continue, :create_backups_record}}
  end

  def handle_continue(:create_backups_record, state) do
    if new_backup_file_creation_required?() do
      Logger.warn "could not find a BackupRecord file for this environment. Creating one now..."
      {:ok, file} = File.open(Memex.Utils.Backups.backup_records_file(), [:write])
      IO.binwrite(file, [] |> Jason.encode!)
      File.close(file)
    end
    {:noreply, state}
  end

  def handle_cast(:commence_backup_procedures, state) do
    Logger.info "#{__MODULE__} commencing backup procedures..."
    case Memex.Utils.Backups.perform_backup_procedure() do
      :backup_successful ->
         {:noreply, state}
      {:error, reason} ->
         Logger.error "#{__MODULE__} could not perform backup, #{inspect reason}"
         {:noreply, state}
    end
  end

  def handle_info(:perform_periodic_check, state) do
    Logger.info "#{__MODULE__} performing periodic check..."
    case Memex.Utils.Backups.fetch_last_backup() do
      :no_backups_found ->
         GenServer.cast(self(), :commence_backup_procedures)
         Process.send_after(self(), :perform_periodic_check, @status_check_period)
         {:noreply, state}
      last_backup = %Memex.BackupRecord{} ->
         if last_backup |> is_older_than_cutoff?() do
           GenServer.cast(self(), :commence_backup_procedures)
         end
         Process.send_after(self(), :perform_periodic_check, @status_check_period)
         {:noreply, state}
    end
  end

  def new_backup_file_creation_required? do
    not File.exists?(Memex.Utils.Backups.backup_records_file())
  end

  def is_older_than_cutoff?(%{timepoint: unix_time}) when is_integer(unix_time) do
    {:ok, last_backup_time} = DateTime.from_unix(unix_time)
    cutoff = Memex.My.current_time() |> Timex.shift(hours: -1*@autobackup_period_hours)
    last_backup_time |> Timex.before?(cutoff) 
  end
end
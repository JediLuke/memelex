#iex(21)> Memelex.Agents.BackupManager.is_older_than_24_hours?(%{timepoint: My.current_time |> Timex.shift(days: -1) |> DateTime.to_unix})
#true
#iex(22)> Memelex.Agents.BackupManager.is_older_than_24_hours?(%{timepoint: My.current_time |> Timex.shift(hours: -23) |> DateTime.to_unix})
#false

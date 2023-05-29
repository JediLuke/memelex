import Config

# we need to start any applications we depend on in Config files
# {:ok, _} = Application.ensure_all_started(:jason)

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :logger,
       :console,
       # no additional newline
       format: "[$level] $message $metadata\n"

config :memelex,
  text_editor_shell_command: "subl"

import_config "#{config_env()}.exs"

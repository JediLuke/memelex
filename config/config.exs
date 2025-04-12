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

config :nx, default_backend: EXLA.Backend
config :nx, :default_defn_options, [compiler: EXLA]

# config :exla, [
#   default_client: :cuda,
#   clients: [
#     host: [platform: :host, preallocate: false, memory_fraction: 0.5],
#     cuda: [platform: :cuda]
#   ]
# ]

import_config "#{config_env()}.exs"

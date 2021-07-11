import Config


config :elixir,
  :time_zone_database, Tzdata.TimeZoneDatabase

config :logger,
  :console,
     format: "[$level] $message $metadata\n" # I like to remove the newline, which is there by default

import_config "#{config_env()}.exs"
import Config


config :elixir,
  :time_zone_database, Tzdata.TimeZoneDatabase

config :logger,
  :console,
     format: "[$level] $message $metadata\n" # I like to remove the newline, which is there by default

config :scenic, :assets,
  module: Memelex.Assets

config :memelex,
  text_editor_shell_command: "subl"

import_config "#{config_env()}.exs"
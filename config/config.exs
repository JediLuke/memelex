import Config


config :elixir,
  :time_zone_database, Tzdata.TimeZoneDatabase

config :logger,
  :console,
     format: "[$level] $message $metadata\n" # I like to remove the newline, which is there by default

config :memelex,
  text_editor_shell_command: "gedit"


config :memelex,
  environment: %{
    name: "Telaranrhiod",
    memex_directory: "/Users/luke/memex/Telaranrhiod",
    # backups_directory: "/Volumes/Samsung\ USB/memex_backups/"
  }


import_config "#{config_env()}.exs"
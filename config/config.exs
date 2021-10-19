import Config


config :elixir,
  :time_zone_database, Tzdata.TimeZoneDatabase

config :logger,
  :console,
     format: "[$level] $message $metadata\n" # I like to remove the newline, which is there by default

config :memex,
  text_editor_shell_command: "subl"

config :memex,
  environment: %{
    name: "JediLuke",
    memex_directory: "/Users/luke/memex/JediLuke",
    backups_directory: "/Users/luke/memex/backups/JediLuke"
  }


import_config "#{config_env()}.exs"
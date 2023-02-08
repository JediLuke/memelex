import Config


config :elixir,
  :time_zone_database, Tzdata.TimeZoneDatabase

config :logger,
  :console,
     format: "[$level] $message $metadata\n" # I like to remove the newline, which is there by default

config :scenic, :assets,
  module: Memelex.App.Scenic.Assets

config :memelex,
  run_in_gui_mode?: false, # this way, we can still execute Memelex as a command line application... we can still use RadicStore / WikiManager, nothing should really change...
  text_editor_shell_command: "subl"

import_config "#{config_env()}.exs"
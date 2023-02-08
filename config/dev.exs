import Config

@memex "Paracelcus23"

#NOTE - this config is here, and NOT in the top-level config,
#       because we want it to be impossible to accidentally
#       run the tests against thie config! Then the tests would
#       overwrite our real Memex! So we define it at the MIX_ENV level.
config :memelex,
  environment: %{
    name: @memex,
    memex_directory: "/Users/luke/memex/#{@memex}_copy",
    backups_directory: "/Users/luke/memex/backups/#{@memex}_copy"
  }

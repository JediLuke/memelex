import Config

config :logger,
  level: :warning

config :memex,
  environment: %{
    name: "Tel'aran'rhiod", # https://wot.fandom.com/wiki/Tel%27aran%27rhiod
    memex_directory: "/home/pi/memex/_test"
  }
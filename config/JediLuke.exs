import Config

config :memelex,
  active?: true,
  environment: %{
    name: "JediLuke",
    memex_directory: "/home/luke/memex/JediLuke", # todo change the name of this field to `fs_root_dir` -> file system root directory (for the memex)
    backups_directory: "/home/luke/memex/backups/JediLuke" # todo change this to `fs_backups_dir`
  }

IO.puts "booting into `JediLuke`..."

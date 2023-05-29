import Config


# # e.g. `/home/luke/.memex`
# memex_dotfile = System.user_home!() <> "/.memex"

# # attempt to read the .memex file for this user
# {memex_active?, memex_env} =
#   case File.read(memex_dotfile) do
#     {:ok, data} ->
#         env = Jason.decode!(data)
#         IO.puts "Loading Memex data for `#{env["name"]}`..."
#         {true, env}
#     {:error, _reason} ->
#         IO.puts "Unable to find a Memex dotfile... continuing without Memex functionality."
#         {false, %{}}
#   end

# config :memelex,
#   active?: memex_active?,
#   environment: %{
#     name: memex_env["name"],
#     memex_directory: "#{memex_env["memex_directory"]}",
#     backups_directory: "#{memex_env["backups_dir"]}"
#   }

# if memex_active? do
#   IO.puts "loaded #{memex_env["name"]}."
# else
#   IO.puts "no Memex was loaded."
# end

config :memelex,
  active?: false,
  # environment: %{
  #   name: @memex,
  #   memex_directory: "/Users/luke/memex/#{@memex}_copy",
  #   backups_directory: "/Users/luke/memex/backups/#{@memex}_copy"
  # }

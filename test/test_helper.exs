

v = Mix.Project.config[:version]
IO.inspect v, label: "Version under test"

#env = Application.get_env(:memex, :environment)

# pre-test setup
#IO.puts "\nCreating new Memex environment..."
#TODo I don't like this... I can just see myself accidentally deleting my Memex one day
# at the very least I want backups working before I go too far down this path
#System.cmd("rm", ["-rf", env[:memex_directory]])
#System.cmd("mkdir", [env[:memex_directory]])

# The default Elixir behaviour is to start the application
# before running all tests. In this case, we need to create
# the test environment first - so we do that above, and then
# start the application here.
# https://virviil.github.io/2016/10/26/elixir-testing-without-starting-supervision-tree/
# https://groups.google.com/g/elixir-lang-talk/c/YCWfXQMRL1Y/m/uWuu777cLO4J

ExUnit.start()


# test cleanup
#System.cmd("echo", ["hello"])
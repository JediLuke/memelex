

v = Mix.Project.config[:version]
IO.inspect v, label: "\n\nVersion under test"

env = Application.get_env(:memelex, :environment)

if env.memex_directory != "/home/pi/memex/_test" do
  raise "invalid test Memex!!"
end

# pre-test setup
IO.puts "re-creating test Memex environment..."
System.cmd("rm", ["-rf", env[:memex_directory]])
System.cmd("mkdir", [env[:memex_directory]])

# The default Elixir behaviour is to start the application
# before running all tests. In this case, we need to create
# the test environment first - so we do that above, and then
# start the application here.
# https://virviil.github.io/2016/10/26/elixir-testing-without-starting-supervision-tree/
# https://groups.google.com/g/elixir-lang-talk/c/YCWfXQMRL1Y/m/uWuu777cLO4J

Application.ensure_all_started(:memelex)

#IDEA: use excluse: :test, include: first_pass or something
ExUnit.start() #TODO here we should pass in flags, only run the "clean memex" tests, then next time, we can set up another environment, run those ones... 

#TODO so what we need now, is to shut down the memex, & reboot it, to test that all works...

# test cleanup
System.cmd("echo", ["Tests complete."])
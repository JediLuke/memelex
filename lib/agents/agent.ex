defmodule Memelex.Agent do
  alias Memelex.Lib.Structs.MemexConcepts

  require Logger

  def all do
    Memelex.My.Wiki.search(tagged: "agent")
  end

  def add_to_memex(%MemexConcepts.Agent{} = agent) do
    Memelex.My.Wiki.new(%{
      title: "Agent: #{agent.name}",
      data: agent,
      tags: ["agent"],
      type: {:struct, MemexConcepts.Agent}
    })
  end

  def add_to_memex(args) do
    args
    |> MemexConcepts.Agent.new()
    |> add_to_memex()
  end

  # def start_agent(%Memelex.TidBit{data: agent}) do
  #   start_agent(agent)
  # end

  def start_agent(memex_env, %MemexConcepts.Agent{
        config: %{
          "file_path" => file_path,
          # note we don't accept any params for an agent (yet!?>)
          "mfa" => {agent_mod, :start_link, [[]]},
          "type" => "gen_server"
        }
      }) do
    # IO.puts("here we should start: #{inspect(agent)}")

    # raise "not implemented yet"
    IO.puts("STARTING AGENT: #{inspect(agent_mod)}")

    agent_elixir_file =
      memex_env.memex_directory
      |> Path.join(file_path)
      |> IO.inspect(label: "agent_elixir_file")

    [^agent_mod] = IEx.Helpers.c(agent_elixir_file)

    IO.puts("COMPILED")
    # TODO here we need to load the module, and then call the start_link function
    {:module, _mod} = Code.ensure_loaded(agent_mod)
    IO.puts("LOADED")

    {:ok, _pid} = res = GenServer.start_link(agent_mod, %{})

    IO.puts("STARTED")

    res
    # %Memelex.Lib.Structs.MemexConcepts.Agent{
    #   name: "YesMan",
    #   status: :active,
    #   last_activity: ~U[2023-09-02 15:53:21.151335Z],
    #   config: %{
    #     "filepath" => "agents/yes_men.ex",
    #     "mfa" => {Memelex.My.Agents.YesMan, :start_link, [[]]},
    #     "type" => "gen_server"
    #   }
    # }
  end

  def start_agent(_memex_env, agent) do
    Logger.warn("Unable to start agent: #{inspect(agent)}")
    :error
  end

  def save_system_agent(%MemexConcepts.MemexEnv{} = memex_env, :yes_man) do
    save_system_agent(memex_env, %{
      name: "YesMan",
      module: Memelex.My.Agents.YesMan,
      file_path: "agents/yes_man.ex"
    })
  end

  def save_system_agent(%MemexConcepts.MemexEnv{} = memex_env, %{
        name: agent_name,
        module: agent_module,
        file_path: agent_code_file_path
      }) do
    save_new_agent_file_into_the_memex(
      memex_env,
      agent_module,
      agent_code_file_path
    )

    agent = %MemexConcepts.Agent{
      name: agent_name,
      config: %{
        "type" => "gen_server",
        "file_path" => agent_code_file_path,
        "mfa" => {agent_module, :start_link, [[]]}
      }
    }

    add_to_memex(agent)
  end

  def save_new_agent_file_into_the_memex(
        %MemexConcepts.MemexEnv{} = memex_env,
        agent_module,
        agent_filepath
      ) do
    # generate the code for the agent
    {:ok, agent_code} = gen_server_agent_creator(agent_module)

    # save the new agent file inside the memex
    file_path = Path.join(memex_env.memex_directory, agent_filepath)
    File.write!(file_path, agent_code)

    %{file_path: file_path}
  end

  # def save_system_agent(%MemexConcepts.MemexEnv{} = memex_env, :money_penny) do
  #   # 1) Copy the template agent into the memex`

  #   # generate the code for the agent
  #   {:ok, agent_code} = gen_server_agent_creator(Memelex.My.Agents.MoneyPenny)

  #   # save the new agent file inside the memex
  #   file_path = Path.join(memex_env.memex_directory, "agents/money_penny.ex")
  #   File.write!(file_path, agent_code)

  #   # 2) Create an %Agent{} struct & add to memex
  #   agent = %MemexConcepts.Agent{
  #     name: "MoneyPenny",
  #     config: %{
  #       "type" => "gen_server",
  #       "filepath" => file_path,
  #       "mfa" => {Memelex.My.Agents.MoneyPenny, :start_link, [[]]}
  #     }
  #   }

  #   add_to_memex(agent)
  # end

  def gen_server_agent_creator(module_name) do
    code = gen_server_agent_creator(:on_loop, module_name)
    {:ok, code}
  end

  def gen_server_agent_creator(:inert, module_name) do
    """
    defmodule #{module_name} do
      use GenServer

      def start_link(_args) do
        GenServer.start_link(__MODULE__, %{})
      end

      def init(state) do
        {:ok, state}
      end
    end
    """
  end

  def gen_server_agent_creator(:on_loop, module_name) do
    """
    defmodule #{module_name} do
      use GenServer
      require Logger

      # Client API

      def start_link(_opts) do
        GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
      end

      # GenServer callbacks

      def init(_state) do
        schedule_work(thirty_seconds())
        {:ok, %{}}
      end

      def handle_info(:work, state) do
        Logger.info("Yes Sir/Madam!")
        schedule_work(thirty_seconds())
        {:noreply, state}
      end

      # Helper function to schedule work
      defp schedule_work(interval) do
        Process.send_after(self(), :work, interval)
      end

      defp thirty_seconds(), do: :timer.seconds(30)
    end
    """
  end
end

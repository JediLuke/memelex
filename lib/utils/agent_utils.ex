defmodule Memelex.Utils.AgentUtils do
  # alias Memelex.Lib.Structs.MemexConcepts.MemexEnv
  alias Memelex.Lib.Structs.MemexConcepts.V01.Agent

  require Logger

  def write_agent_module_file(
        %Memelex.Environment{} = memex_env,
        %Memelex.TidBit{
          uuid: t_uuid,
          data:
            %Agent{
              config: %{
                # "type" => "gen_server",
                "mfa" => {agent_module, :start_link, [[]]}
              }
            } = agent
        } = agent_t
      ) do
    # agent_filepath = "agents/#{to_snake_case(agent.name)}.ex"
    full_file_path = Path.join(memex_env.memex_directory, agent_filepath(agent))

    if File.exists?(full_file_path) do
      raise "The agent file already exists: #{full_file_path}"
    else
      # generate the code for the agent
      {:ok, agent_code} = agent_codegen(agent_t)
      # {:ok, agent_code} = gen_server_agent_creator(agent_module, agent.name)

      # save the new agent file inside the memex
      :ok = File.write!(full_file_path, agent_code)
      {:ok, full_file_path}

      # # load the file into our BEAM runtime
      # Memelex.Environment.compile_and_load_file(full_file_path)
    end
  end

  def delete_agent_file(memex_env, %Agent{} = agent) do
    File.rm!(full_agent_filepath(memex_env, agent))
  end

  def full_agent_filepath(%Memelex.Environment{memex_directory: dir}, agent) do
    Path.join(dir, agent_filepath(agent))
  end

  def agent_filepath(%Agent{name: name}) do
    "agents/#{to_snake_case(name)}.ex"
  end

  # def add_to_memex(%MemexConcepts.V01.Agent{} = agent) do
  #   Memelex.My.Wiki.new(%{
  #     title: "Agent: #{agent.name}",
  #     data: agent,
  #     tags: ["my_agents"],
  #     type: {:struct, MemexConcepts.V01.Agent}
  #   })
  # end

  # def add_to_memex(args) do
  #   args
  #   |> MemexConcepts.V01.Agent.new()
  #   |> add_to_memex()
  # end

  def start_agent(%Memelex.TidBit{data: agent}) do
    start_agent(agent)
  end

  def start_agent(memex_env, %Agent{
        config: %{
          # note we don't accept any params for an agent (yet!?>)
          "type" => "gen_server",
          "mfa" => {agent_mod, :start_link, [[]]}
        }
      }) do
    # this should all be already loaded when we booted the memex...

    # agent_elixir_file =
    #   memex_env.memex_directory
    #   |> Path.join(file_path)

    # # TODO check if compiles in a safer way here
    # [^agent_mod] = IEx.Helpers.c(agent_elixir_file)
    # {:module, _mod} = Code.ensure_loaded(agent_mod)

    GenServer.start_link(agent_mod, %{})
  end

  def start_agent(_memex_env, agent) do
    Logger.warn("Unable to start agent: #{inspect(agent)}")
    :error
  end

  # what do I want the first agent to do?? Improve the memex...
  # def new_agent(%{name: name}) do

  # end

  def save_agent(%Memelex.Environment{} = memex_env, :yes_man) do
    save_agent(memex_env, %{
      name: "YesMan",
      module: Memelex.My.Agents.YesMan,
      file_path: "agents/yes_man.ex"
    })
  end

  def save_agent(%Memelex.Environment{} = memex_env, :moneypenny) do
    save_agent(memex_env, %{
      name: "MoneyPenny",
      module: Memelex.My.Agents.MoneyPenny,
      file_path: "agents/moneypenny.ex"
    })
  end

  # def save_agent(%MemexEnv{} = memex_env, %{
  #       name: agent_name,
  #       module: agent_module,
  #       file_path: agent_code_file_path
  #     }) do
  #   save_new_agent_file_into_the_memex(
  #     memex_env,
  #     agent_module,
  #     agent_code_file_path
  #   )

  #   agent = %Agent{
  #     name: agent_name,
  #     config: %{
  #       "type" => "gen_server",
  #       "file_path" => agent_code_file_path,
  #       "mfa" => {agent_module, :start_link, [[]]}
  #     }
  #   }

  #   add_to_memex(agent)
  # end

  # def save_new_agent_file_into_the_memex(
  #       %MemexEnv{} = memex_env,
  #       agent_module,
  #       agent_filepath
  #     ) do
  #   # generate the code for the agent
  #   {:ok, agent_code} = gen_server_agent_creator(agent_module)

  #   # save the new agent file inside the memex
  #   file_path = Path.join(memex_env.memex_directory, agent_filepath)
  #   File.write!(file_path, agent_code)

  #   compile_and_load_file

  #   %{file_path: file_path}
  # end

  # def save_agent(%MemexConcepts.MemexEnv{} = memex_env, :money_penny) do
  #   # 1) Copy the template agent into the memex`

  #   # generate the code for the agent
  #   {:ok, agent_code} = gen_server_agent_creator(Memelex.My.Agents.MoneyPenny)

  #   # save the new agent file inside the memex
  #   file_path = Path.join(memex_env.memex_directory, "agents/money_penny.ex")
  #   File.write!(file_path, agent_code)

  #   # 2) Create an %Agent{} struct & add to memex
  #   agent = %MemexConcepts.V01.Agent{
  #     name: "MoneyPenny",
  #     config: %{
  #       "type" => "gen_server",
  #       "filepath" => file_path,
  #       "mfa" => {Memelex.My.Agents.MoneyPenny, :start_link, [[]]}
  #     }
  #   }

  #   add_to_memex(agent)
  # end

  def agent_codegen(%Memelex.TidBit{
        uuid: agent_t_uuid,
        data: %Agent{
          name: agent_name,
          config: %{
            # "type" => "gen_server",
            "mfa" => {agent_module, :start_link, [[]]}
          }
        }
      }) do
    # make agents inactive by default
    agent_active? = false

    code = """
    defmodule #{agent_module} do
      @agent_active? #{agent_active?}
      use Memelex.Agents.Behaviour

      def uuid, do: "#{agent_t_uuid}"

      def tag, do: "#{to_snake_case(agent_name)}"

      def do_work(state) do
        IO.puts "#{agent_name} is doing work!"
        {:ok, state}
      end
    end
    """

    {:ok, code}
  end

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

      def handle_call(:shutdown, _from, state) do
        # Perform cleanup operations or any other logic you need before shutting down
        # ...

        # Then, stop the GenServer
        {:stop, :normal, state}
      end


      def handle_info(:work, state) do
        Logger.info("#{module_name} ready.")
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

  # # fire the action to trigger changing us to the agents screen
  # def show_agents do
  #   raise "need to throw event here"
  #   # Flamelex.Fluxus.action({Flamelex.Fluxus.RadixReducer, :show_agents})
  # end

  defp to_snake_case(string) do
    string
    |> String.split(~r/[^a-zA-Z0-9]+/)
    |> Enum.map(&String.downcase/1)
    |> Enum.join("_")
  end
end

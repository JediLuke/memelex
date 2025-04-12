defmodule Memelex.My.Agents do
  alias Memelex.Lib.Structs.MemexConcepts.V01.Agent

  def show do
    Memelex.Fluxus.event(:show_agents)
  end

  # TODO need to make sure this agent doesn't exist already yet (by title?)
  def new(%Agent{} = agent) do
    memex_env = Memelex.Environment.get_environment()

    # TODO need to check if this agent already exists somehow...

    agent_t =
      Memelex.My.Wiki.new(%{
        title: "Agent: #{agent.name}",
        data: agent,
        tags: ["my_agents"],
        type: ["struct", Agent]
      })

    {:ok, module_file_path} = Memelex.Utils.AgentUtils.write_agent_module_file(memex_env, agent_t)
    [{_module, _bytecode}] = Code.load_file(module_file_path)

    # Memelex.Environment.compile_and_load_file(full_file_path)

    # and start the agent...
    Memelex.AgentHandler.boot_agent(agent)
  end

  def activate(agent) do

  end

  def new(%{"name" => name} = args) do
    # agent_name = to_camel_case(name)

    # NOTE we need to put "Elixir." in front of the module name because we use String.to_existing_atom
    # later down the line, and that atom must start with ELixir. for it to already exist
    agent_module = String.to_atom("Elixir.Memelex.My.Agents." <> name)
    # agent_module = "Elixir.Memelex.My.Agents." <> name

    config =
      args["config"] ||
        %{}
        # |> Map.put("type", "gen_server")
        |> Map.put("mfa", {agent_module, :start_link, [[]]})

    %Agent{} =
      structified_args =
      args
      |> Map.put("config", config)
      |> Agent.new()

    new(structified_args)
  end

  def new(name) when is_bitstring(name) do
    new(%{"name" => name})
  end

  def new do
    raise "Must at least give the agent a name!"
  end

  def all do
    Memelex.My.Wiki.find_all(tagged: "my_agents")
  end

  def all(opt_key) when opt_key in [:t, :titles] do
    all() |> Enum.map(& &1.title)
  end

  def list do
    all() |> Enum.map(& &1.title)
  end

  def delete(%Memelex.TidBit{} = tidbit) do
    # shut down the process
    Memelex.AgentHandler.shutdown_agent(tidbit)

    # delete the tidbit (which should also delete the file)
    Memelex.My.Wiki.delete(tidbit)
  end

  # this function specifically loads up the Agents page in the GUI
  def show do
    # fire an event which will be ignored by Memelex but picked up by Flamelex
    # TODO print a warning if we're not in GUI mode or whatever
    Memelex.Fluxus.event(:show_agents)
  end

  defp to_camel_case(string) do
    string
    |> String.split(~r/[^a-zA-Z0-9]+/)
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join("")
  end

  defp to_snake_case(string) do
    string
    |> String.split(~r/[^a-zA-Z0-9]+/)
    |> Enum.map(&String.downcase/1)
    |> Enum.join("_")
  end
end

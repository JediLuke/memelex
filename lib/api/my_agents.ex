defmodule Memelex.My.Agents do
  alias Memelex.Lib.Structs.MemexConcepts.V01.Agent

  def new(%Agent{} = agent) do
    memex_env = Memelex.Environment.get_environment()
    :ok = Memelex.Utils.AgentUtils.save_and_load_agent_file(memex_env, agent)

    Memelex.My.Wiki.new(%{
      title: "Agent: #{agent.name}",
      data: agent,
      tags: ["my_agents"],
      type: {:struct, Agent}
    })

    # and start the agent...
    Memelex.AgentHandler.boot_agent(agent)
  end

  def new(%{"name" => name} = args) do
    agent_name = to_camel_case(name)
    agent_module = String.to_atom("Elixir.Memelex.My.Agents." <> agent_name)

    config =
      (args["config"] || %{})
      |> Map.put("type", "gen_server")
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
    Memelex.My.Wiki.search(tagged: "my_agents")
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
    Memelex.Utils.EventWrapper.event(:show_agents)
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

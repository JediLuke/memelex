defmodule Memelex.My.Projects do
  alias Memelex.WikiServer
  alias Memelex.Lib.Structs.MemexConcepts.V01.Project

  # TODO we should accept args here, maybe we want to be able to accept extra tags or something
  def new(%Project{} = project) do
    # IO.inspect(project, label: "PPPP")

    # require IEx
    # IEx.pry()
    # title = "Project: #{project.name}"

    Memelex.My.Wiki.new(%{
      title: "Project: #{project.name}",
      data: project,
      tags: ["my_projects"],
      type: {:struct, Project}
    })
  end

  def new(name) when is_bitstring(name) do
    %Project{} = proj = Project.new(%{name: name})
    new(proj)
  end

  # def new(args) do
  #   args |> Project.new() |> new()
  # end

  def all do
    {:ok, wiki} = GenServer.call(WikiServer, :list_all_tidbits)
    wiki |> Enum.filter(fn tidbit -> tidbit.tags |> Enum.member?("my_projects") end)
  end
end

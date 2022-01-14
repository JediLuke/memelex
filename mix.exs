defmodule Memelex.MixProject do
  use Mix.Project

  @release "0.0.1"

  def project do
    [
      app: :memelex,
      version: @release <> "-#{Mix.env()}-" <> git_commit_hash(),
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Memelex.Application, []}
    ]
  end

  defp aliases do
    [
      test: "test --no-start" #(2)
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:elixir_uuid, "~> 1.2"},
      {:timex, "~> 3.7.5"},
    ]
  end

  def git_commit_hash() do
    {sha_hash, 0} = System.cmd("git", ["rev-parse", "--short", "HEAD"])
    sha_hash |> String.trim()
  end

end

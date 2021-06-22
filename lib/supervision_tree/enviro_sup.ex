defmodule Memex.EnvironmentSupervisor do
  use Supervisor

  def start_link(params) do
    Supervisor.start_link(__MODULE__, params, name: Memex.EnvironmentSupervisor)
  end

  @impl true
  def init(env_map) do

    children = [
      {Memex.Env.ExecutiveManager, env_map}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
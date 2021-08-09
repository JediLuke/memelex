defmodule Memex.EnvironmentSupervisor do
  use Supervisor

  def start_link(params) do
    Supervisor.start_link(__MODULE__, params, name: Memex.EnvironmentSupervisor)
  end

  @impl true
  def init(env_map) do

    children = [
      {Task.Supervisor, name: Memex.Env.TaskSupervisor},
      {Memex.Env.ExecutiveManager, env_map},
      Memex.MoneyPenny # agents are started after the main Memex, since they need access to it
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
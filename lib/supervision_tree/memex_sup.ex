defmodule Memelex.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: Memelex.Supervisor)
  end

  @impl true
  def init(env) do

    children = [
      # {Task.Supervisor, name: Memelex.Env.TaskSupervisor},
      # {Memelex.Env.ExecutiveManager, env_map},
      # Memelex.MoneyPenny # agents are started after the main Memex, since they need access to it

      {Memelex.EnvironmentSupervisor, env}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
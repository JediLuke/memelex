defmodule Memelex.MoneyPenny do
  use Supervisor

  def start_link(params) do
    Supervisor.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Agent.DynamicSupervisor},
      Memelex.Agents.BackupManager
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
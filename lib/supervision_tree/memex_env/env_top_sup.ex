defmodule Memelex.Environment.TopSupervisor do
  use Supervisor

  def start_link(%{name: name} = args) do
    Supervisor.start_link(__MODULE__, args,
      name: {:via, Registry, {Memelex.EnviroRegistry, {__MODULE__, name}}}
    )
  end

  @impl true
  def init(memex_env) do
    children = [
      {Task.Supervisor, name: Memelex.Environment.TaskSupervisor},
      {Memelex.Environment, memex_env}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # def terminate(reason, %{name: memex_name}) do
  #   Logger.info "#{memex_name} terminating due to #{inspect(reason)}"
  #   :ok
  # end

  # TODOS

  # - try to get a terminate callback from GenServer working in here...
  # - now we can start & stop environments! Need to try and detect flamelex &, if present, bubble an event up to it - then we can start to initialize environments from up there...
end

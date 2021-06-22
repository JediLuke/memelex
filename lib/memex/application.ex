defmodule Memex.Application do
  @moduledoc false
  use Application


  def start(_type, _args) do

    children = [
      Memex.BootCheck,
    ]

    opts = [
      name: Memex.Supervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, opts)
  end
end

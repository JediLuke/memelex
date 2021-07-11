defmodule Memex.Application do
  @moduledoc false
  use Application


  def start(_type, _args) do

    IO.puts "Starting Memex application..."

    children = [
      Memex.BootCheck
    ]

    opts = [
      name: Memex.TopSupervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, opts)
  end
end

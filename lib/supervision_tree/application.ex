defmodule Memelex.Application do
  @moduledoc false
  use Application


  def start(_type, _args) do

    IO.puts "Starting Memex application..."

    children = [
      Memelex.BootCheck
    ]

    opts = [
      name: Memelex.TopSupervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, opts)
  end
end

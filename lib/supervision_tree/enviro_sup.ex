defmodule Memelex.App.EnvironmentSupervisor do
  use DynamicSupervisor
  require Logger

  # TODO one day we should enable loading multiple memexi at the same time...
  # memexi is plural of memex
  @max_open_memexi 1

  # Start the supervisor with the given arguments
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # Initialize the supervisor with the specified max_children and strategy
  @impl true
  def init(init_arg) do
    Logger.info("#{__MODULE__} initializing... #{inspect(init_arg)}")
    DynamicSupervisor.init(max_children: @max_open_memexi, strategy: :one_for_one)
  end

  @doc """
  Start the process-tree for a particular Memex environment.
  """
  def start_env(environment_details) do
    # spec = {Memelex.Environment.TopSupervisor, environment_details, restart: :transient}

    memex_top_mod = Memelex.Environment.TopSupervisor

    DynamicSupervisor.start_child(__MODULE__, %{
      id: memex_top_mod,
      start: {memex_top_mod, :start_link, [environment_details]},
      restart: :transient,
      shutdown: :infinity,
      type: :supervisor
    })
  end

  # # Stop the environment with the specified environment_id
  # def stop_env(environment_id) do
  #   Logger.info("Attempting to stop Memex environment: #{inspect(environment_id)}")

  #   case find_child_with_environment_id(environment_id) do
  #     {:ok, pid} ->
  #       Logger.info("Stopping Memex environment: #{inspect(environment_id)}...")
  #       DynamicSupervisor.terminate_child(__MODULE__, pid)
  #       Logger.info("Stopping Memex environment: done.")
  #       :ok

  #     :error ->
  #       Logger.error("Could not find environment: #{inspect(environment_id)}")
  #       :error
  #   end
  # end

  # # Helper function to find a child with the specified environment_id
  # defp find_child_with_environment_id(environment_id) do
  #   DynamicSupervisor.which_children(__MODULE__)
  #   |> Enum.find_value(fn
  #     {^environment_id, pid, _, _} -> {:ok, pid}
  #     _ -> false
  #   end, :error)
  # end
end

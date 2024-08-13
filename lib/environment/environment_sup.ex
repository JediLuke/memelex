defmodule Memelex.App.EnvironmentSupervisor do
  @moduledoc """
  A DynamicSupervisor which manages the Memex environment processes.
  """
  use DynamicSupervisor
  require Logger

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Initialize the supervisor with the specified max_children and strategy
  @impl true
  # TODO one day we should enable loading multiple memexi at the same time...
  # memexi is plural of memex
  # for now this is here kind of of a safety net against opening up the same memex twice
  @max_open_memexi 1
  def init(_args) do
    Logger.debug("#{__MODULE__} initializing...")
    DynamicSupervisor.init(max_children: @max_open_memexi, strategy: :one_for_one)
  end

  @doc """
  Start the process-tree for a particular Memex environment.
  """
  def start_env(%Memelex.Environment{} = e) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: MemexEnvironment,
      start: {Memelex.Environment.TreeTopSuprvsr, :start_link, [e]},
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

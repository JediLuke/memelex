defmodule Memelex.Agents.Behaviour do
  # @callback init(initial_state :: any()) :: {:ok, state :: any()}
  # @callback handle_write_request(state :: any(), prompt :: String.t()) ::
  #             {:reply, response :: String.t(), new_state :: any()}
  # @callback handle_continue_session(state :: any(), session_id :: String.t()) ::
  #             {:reply, response :: String.t(), new_state :: any()}
  # @callback handle_update_character(state :: any(), character_data :: map()) ::
  #             {:noreply, new_state :: any()}
  # @callback handle_update_plot(state :: any(), plot_details :: map()) ::
  #             {:noreply, new_state :: any()}
  # @callback terminate(reason :: any(), state :: any()) :: :ok

  @callback uuid() :: String.t()
  # TODO consistent agent state?? Agent Superstructs!?!?
  @callback run_boot_sequence() :: map()

  defmacro __using__(_opts) do
    quote do
      use GenServer
      require Logger
      @behaviour Memelex.Agents.Behaviour

      def start_link(_opts) do
        GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
      end

      # Implement default init callback if not defined
      def init(_args) do
        {:ok, [], {:continue, :boot_sequence}}
      end

      def handle_continue(:boot_sequence, _init_state) do
        Logger.debug("#{__MODULE__} starting boot sequence...")

        if @agent_active? do
          Logger.debug("#{__MODULE__} will boot... agent_active?: #{@agent_active?}")
          {:ok, agent_state} = run_boot_sequence()
          {:noreply, agent_state}
        else
          Logger.debug("#{__MODULE__} is inactive. agent_active?: #{@agent_active?}")
          {:noreply, %{}}
        end
      end

      # Injected functions or defaults can go here.
      # For example, a default implementation for terminate:
      def terminate(_reason, _state), do: :ok

      # # Optionally, inject any other common code, such as helper functions
      # defp some_helper_function do
      #   # Some common functionality
      # end

      # # Require the implementing module to provide the specific callbacks
      # @impl true
      # def handle_write_request(state, prompt),
      #   do: raise("handle_write_request/2 must be implemented")

      # @impl true
      # def handle_continue_session(state, session_id),
      #   do: raise("handle_continue_session/2 must be implemented")

      # @impl true
      # def handle_update_character(state, character_data),
      #   do: raise("handle_update_character/2 must be implemented")

      # @impl true
      # def handle_update_plot(state, plot_details),
      #   do: raise("handle_update_plot/2 must be implemented")
    end
  end
end

# defmodule Memelex.Agents.Behaviour do
#   @callback init(initial_state :: any()) :: {:ok, state :: any()}
#   @callback handle_write_request(state :: any(), prompt :: String.t()) ::
#               {:reply, response :: String.t(), new_state :: any()}
#   @callback handle_continue_session(state :: any(), session_id :: String.t()) ::
#               {:reply, response :: String.t(), new_state :: any()}
#   @callback handle_update_character(state :: any(), character_data :: map()) ::
#               {:noreply, new_state :: any()}
#   @callback handle_update_plot(state :: any(), plot_details :: map()) ::
#               {:noreply, new_state :: any()}
#   @callback terminate(reason :: any(), state :: any()) :: :ok

#   @doc """
#   Starts the agent with the given initial state.
#   """
#   def start_link(module, initial_state) do
#     GenServer.start_link(module, initial_state, name: __MODULE__)
#   end

#   @doc """
#   Writes or continues the novel based on a provided prompt.
#   """
#   def write_request(agent, prompt) do
#     GenServer.call(agent, {:write_request, prompt})
#   end

#   @doc """
#   Continues a writing session with a specific session_id.
#   """
#   def continue_session(agent, session_id) do
#     GenServer.call(agent, {:continue_session, session_id})
#   end

#   @doc """
#   Updates the character details in the novel's state.
#   """
#   def update_character(agent, character_data) do
#     GenServer.cast(agent, {:update_character, character_data})
#   end

#   @doc """
#   Updates the plot details in the novel's state.
#   """
#   def update_plot(agent, plot_details) do
#     GenServer.cast(agent, {:update_plot, plot_details})
#   end
# end

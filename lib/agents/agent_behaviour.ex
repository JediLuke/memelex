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
  @callback tag() :: String.t()
  # TODO consistent agent state?? Agent Superstructs!?!?
  # @callback run_boot_sequence() :: map()

  defmacro __using__(_opts) do
    quote location: :keep do
      use GenServer
      require Logger
      @behaviour Memelex.Agents.Behaviour

      @default_work_loop_period :timer.seconds(90)

      def start_link(_opts) do
        GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
      end

      # Implement default init callback if not defined
      def init(_args) do
        {:ok, [], {:continue, :boot_sequence}}
      end

      def handle_continue(:boot_sequence, _init_state) do
        Logger.debug("#{__MODULE__} starting boot sequence...")

        # this `@agent_active?` must be defined above where we use AgentBehaviour !!
        if @agent_active? do
          Logger.debug("#{__MODULE__} will boot... agent_active?: #{@agent_active?}")

          case run_boot_sequence() do
            {:ok, agent_state} when is_map(agent_state) ->
              Logger.debug("#{__MODULE__} boot sequence complete.")
              {:noreply, agent_state}

            {:error, reason} ->
              Logger.error("Failed to boot #{__MODULE__}, #{reason}. Scheduling reboot...")

              schedule_reboot_attempt()
              {:noreply, {:boot_failed, retries: 0}}
          end
        else
          Logger.debug(
            "#{__MODULE__} is inactive. agent_active?: #{@agent_active?}\n\nRemember to define `@agent_active?:true` in your module, above where we use Agent.Behaviour !"
          )

          {:noreply, :inactive}
        end
      end

      def handle_cast({:set_status, status}, %{status: _s} = state) do
        {:noreply, Map.put(state, :status, status)}
      end

      @max_reboot_attempts 5
      def handle_info(:reboot, {:boot_failed, retries: x})
          when is_integer(x) and
                 x >= 0 and x < @max_reboot_attempts do
        Logger.debug("#{__MODULE__} rebooting...")

        case run_boot_sequence() do
          {:ok, agent_state} ->
            {:noreply, agent_state}

          {:error, reason} ->
            Logger.error("Failed to boot #{__MODULE__}, #{reason}. Scheduling reboot...")

            schedule_reboot_attempt()
            {:noreply, {:boot_failed, retries: x + 1}}
        end
      end

      def handle_info(:reboot, {:boot_failed, retries: x}) when is_integer(x) do
        Logger.error("#{__MODULE__} failed to boot after #{inspect(x)} retries...")

        {:noreply, :boot_failed}
      end

      # Injected functions or defaults can go here.
      # For example, a default implementation for terminate:
      def terminate(_reason, _state), do: :ok

      def run_boot_sequence do
        Logger.debug("#{__MODULE__} boot sequence running...")

        case Memelex.My.Wiki.get(%{uuid: uuid()}) do
          {:ok, %Memelex.TidBit{} = t} ->
            Logger.debug("#{__MODULE__} found Agent TidBit: #{inspect(t.title)}")
            find_or_create_log_tidbit(t)
            # schedule_work_loop(t.data)
            {:ok, t.data}

          # `is_binary` is a terrible name, is_binary should be is_bitstring and is_bitsting should be just `is_bitstream` for what should be `div8_
          # maybe `is_utf8_string` or `is_octet_bitstring`
          {:error, reason} when is_binary(reason) ->
            err = "#{__MODULE__} Boot failed! #{reason}"
            Logger.error(err)
            {:error, err}
        end
      end

      def find_or_create_log_tidbit(%Memelex.TidBit{meta: []} = agent_t) do
        Logger.debug(
          "#{__MODULE__} no log found for agent #{inspect(agent_t.title)}, creating one now..."
        )

        %Memelex.TidBit{} = create_new_log_tidbit(agent_t)
      end

      # TODO handle cases where there is more stuff in the meta for a particular tidbit, maybe shouldn't use meta for this at all...
      def find_or_create_log_tidbit(
            %Memelex.TidBit{meta: [%{"logfile_uuid" => logfile_uuid}]} = agent_t
          )
          when is_binary(logfile_uuid) do
        # case Memelex.My.Wiki.get(logfile_uuid) do
        #   nil ->
        #     raise "Expected #{agent_t.title} to have a log TidBit with uuid #{logfile_uuid}, but we couldn't find one."

        #   %Memelex.TidBit{} = log_t ->
        #     Logger.debug(
        #       "#{__MODULE__} found log #{log_t.title} for agent #{inspect(agent_t.title)}"
        #     )

        #     log_t
        # end
        case Memelex.My.Wiki.get(logfile_uuid) do
          {:ok, %Memelex.TidBit{} = log_t} ->
            Logger.debug("#{__MODULE__} found #{log_t.title}")
            log_t

          {:error, reason} ->
            raise "Expected #{agent_t.title} to have a log TidBit with uuid #{logfile_uuid}, but we couldn't find one.\n\n#{inspect(reason)}"
        end
      end

      def create_new_log_tidbit(%Memelex.TidBit{} = agent_t) do
        # TODO use linking here probably
        log_t =
          Memelex.My.Wiki.new(%{
            title: "Log for #{agent_t.title}",
            type: {:external, :textfile},
            tags: [tag()],
            data: {:filepath, agent_log_filepath(agent_t)},
            meta: [%{"agent_uuid" => agent_t.uuid}]
          })

        # now update the original agent TidBit
        add_logfile_tidbit_to_meta(agent_t, log_t)

        log_t
      end

      def add_logfile_tidbit_to_meta(%Memelex.TidBit{} = agent_t, log_t) do
        Memelex.My.Wiki.update(agent_t, {:add_meta, %{"logfile_uuid" => log_t.uuid}})
      end

      @agent_logs_directory "/logs/agents"
      def agent_log_filepath(agent_t) do
        # get the directory we want to save the agent logs in
        directory =
          Memelex.Utils.ToolBag.memex_directory()
          |> Path.join(@agent_logs_directory)

        # create the directory if it doesn't exist yet
        if not File.exists?(directory) do
          File.mkdir_p(directory)
        end

        # get full filepath for the new file
        filename = tag() <> "_log.txt"
        external_filepath = directory |> Path.join("/#{filename}")

        # make a new text file if one hasn't been created yet
        if not File.exists?(external_filepath) do
          {:ok, file} = File.open(external_filepath, [:write])
          IO.binwrite(file, initial_log(agent_t) <> "\n\n")
          File.close(file)
        end

        external_filepath
      end

      def initial_log(agent_t) do
        ~s|Initial log for #{agent_t.title}\n\n#{inspect(agent_t.data)}\n\n===\n\n|
      end

      def tidbit do
        Memelex.My.Wiki.get!(%{uuid: uuid()})
      end

      def set_status(status) do
        GenServer.cast(__MODULE__, {:set_status, status})
      end

      @five_seconds :timer.seconds(5)
      def schedule_reboot_attempt do
        schedule_reboot_attempt(@five_seconds)
      end

      def schedule_reboot_attempt(timer) do
        Process.send_after(self(), :reboot, timer)
      end

      # a helper function to schedule the next work-loop iteration
      def schedule_work_loop(%{status: :active}) do
        # we can optionally declare `@loop_timer` in the using module
        Process.send_after(self(), :work, @loop_timer || @default_work_loop_period)
      end

      def schedule_work_loop(%{status: s}) do
        Logger.debug("#{__MODULE__} has status: #{inspect(s)}, not scheduling work loop.")
        nil
      end

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

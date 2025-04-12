defmodule Memelex.Agents.Behaviour do
  @moduledoc """
  Agent Behaviour Module.

  Agents implementing this behaviour must go through the following activation workflow:
    1. Perceive:    Scan project state and update beliefs.
    2. Deliberate:  Identify tasks and prioritize work.
    3. Plan:        Break down tasks into actionable steps.
    4. Execute:     Perform work atomically and safely.
    5. Adapt:       Log results and adjust plans accordingly. For reflection & self-improvement.
  """
  alias Memelex.Lib.Structs.MemexConcepts.V01.Agent

  @callback perceive(state :: map()) :: {:ok, map()} | {:error, term()}
  # @callback deliberate(state :: map()) :: {:ok, list()} | {:error, term()}
  @callback plan(state :: map()) :: {:ok, list()} | {:error, term()}
  @callback act(state :: map()) :: {:ok, map()} | {:error, term()}
  @callback adapt(state :: map()) :: {:ok, map()} | {:error, term()}

  # https://github.com/TypedLambda/eresye
  # https://github.com/gleber/exat

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



#   3. Activation Flow

# When the agent is activated, the following workflow ensures meaningful actions:

#     Perceive:
#         Scan project state (files, processes, user commands).
#         Update beliefs.

#     Deliberate:
#         Identify tasks/goals.
#         Prioritize work based on utility or urgency.

#     Plan:
#         Decompose goals into smaller tasks (HTNs).
#         Validate feasibility.

#     Execute:
#         Perform actions safely and atomically.
#         Report success, failure, or partial progress.

#     Adapt:
#         Log results for learning.
#         Update plans or propose alternative strategies.


  @callback uuid() :: String.t()
  @callback tag() :: String.t()
  # TODO consistent agent state?? Agent Superstructs!?!?
  # @callback run_boot_sequence() :: map()
  # @callback do_work(map()) :: {:ok, map()}

  defmacro __using__(_opts) do
    quote location: :keep do
      use GenServer
      alias Memelex.Lib.Structs.MemexConcepts.V01.Agent
      alias Memelex.Utils.LLMs
      alias Memelex.Agents.PromptLib
      require Logger
      @behaviour Memelex.Agents.Behaviour

      def start_link(_opts) do
        # NOTE: agent process registration happens here
        GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
      end

      def init(_args) do
        Logger.debug("#{__MODULE__} booting up...")
        {:ok, %{}, {:continue, :boot_sequence}}
      end

      @doc """
      Return the TidBit for this Agent from the Memex.

      Uses the `uuid()` callback to get the uuid of the Agent.
      """
      def tidbit, do: Memelex.My.Wiki.get!(%{uuid: uuid()})

      # @doc """
      # Send a message to the agent.
      # """
      # def chat(message) do
      #   GenServer.cast(__MODULE__, {:chat_message, message})
      # end

      # @doc """
      # Queue up an instruction in the processing queue.
      # """
      # def instruct(instruction) do
      #   GenServer.cast(__MODULE__, {:instruction, instruction})
      # end

      # def read_log do
      #   GenServer.call(__MODULE__, :read_log)
      # end

      # def logfile, do: get_logfile()

      # def get_logfile do
      #   [%{"logfile_uuid" => logfile_uuid}] = tidbit().meta
      #   Memelex.My.Wiki.get!(%{uuid: logfile_uuid})
      # end

      @doc """
      Fetch the state of the Agent - the whole state, as a %TidBit{}
      """
      # def get_state do
      #   GenServer.call(Module.concat(Elixir, __MODULE__), :get_state)
      # end

      # def sit_rep do
      #   get_state().data.state["sit_rep"]
      # end

      # def put_agent_state(map) do
      #   GenServer.cast(__MODULE__, {:put_agent_state, map})
      # end

      # def merge_agent_state(map) do
      #   GenServer.cast(__MODULE__, {:merge_agent_state, map})
      # end

      # @valid_statuses [:active, :inactive, :manual, :special]
      # def set_status(status) when status in @valid_statuses do
      #   GenServer.cast(__MODULE__, {:set_status, status})
      # end

      # def put_agent_config(map) do
      #   GenServer.cast(__MODULE__, {:put_agent_config, map})
      # end

      # def put_working_memory(map) do
      #   GenServer.cast(__MODULE__, {:put_working_memory, map})
      # end

      # def put_processing_queue(p_queue) do
      #   GenServer.cast(__MODULE__, {:put_processing_queue, p_queue})
      # end

      # def merge_working_memory(map) do
      #   GenServer.cast(__MODULE__, {:merge_working_memory, map})
      # end

      # @doc """
      # Return the last message in the chat history.
      # """
      # def last_response do
      #   get_state().data.state["chat_history"] |> List.last()
      # end

      # def seed_system_prompt(
      #       %{"sys_prompt" => _sys_prompt, "instruction_prompt" => _instruction_prompt} = prompts
      #     ) do
      #   GenServer.cast(__MODULE__, {:seed_system_prompt, prompts})
      # end

      def save do
        GenServer.cast(__MODULE__, :save)
      end

      # make a `reload` functuion which can stop the server (if it's started) and reload the genserver
      # and we also probably need to reload the underlying agent code aswell
      # def reboot do
      #   GenServer.cast(__MODULE__, :reboot)
      # end

      def handle_continue(:boot_sequence, _init_state) do
        Logger.debug("#{__MODULE__} starting boot sequence...")

        case run_boot_sequence() do
          {:ok, %Memelex.TidBit{data: %Agent{status: :active}} = agent_t} ->
            schedule_work_loop(agent_t)
            Logger.debug("#{__MODULE__} boot sequence complete. Agent is active.")
            {:noreply, agent_t}

          {:ok, %Memelex.TidBit{data: %Agent{status: s}} = agent_t}  ->
            Logger.debug("#{__MODULE__} has status: #{inspect s}")
            {:noreply, agent_t}

          {:error, reason} ->
            Logger.error("Failed to boot #{__MODULE__}, #{reason}. Scheduling reboot...")
            schedule_reboot_attempt()
            {:noreply, {:boot_failed, retries: 0}}
        end
      end

      def handle_call(:activate, _from, %Memelex.TidBit{data: %Agent{status: :inactive} = _t} = t_state) do
        # save the new TidBit state to disc (& broadcast event of said save)
        {:ok, new_t_state} = Memelex.My.Wiki.modify(t_state, %{agent_status: :active})

        schedule_work_loop(new_t_state)

        {:reply, {:ok, new_t_state}, new_t_state}
      end

      def handle_call(:deactivate, _from, %Memelex.TidBit{data: %Agent{} = _a} = t_state) do
        # save the tidbit as active in the *actual* memex (hard disk)
        # this will then broadcast a tidbit_saved event that flamelex needs
        # to catch & propagate
        {:ok, new_t_state} = Memelex.My.Wiki.modify(t_state, %{agent_status: :inactive})

        {:reply, {:ok, new_t_state}, new_t_state}
      end

      def handle_call(:get_state, _from, state) do
        {:reply, state, state}
      end


      # def handle_call(:nudge, _from, %Memelex.TidBit{data: %Agent{loop_phase: :perceive} = ag_state} = state) do
      #   IO.puts "HANDLING NUDGE CALL"
      #   case perceive(state) do
      #     {:ok, percepts} ->
      #       Logger.info "finished perceiving... #{inspect percepts}"
      #       agent_state = %{ag_state|percepts: percepts, loop_phase: :plan}
      #       IO.inspect(agent_state, label: "AG AG AG AG AG")
      #       {:ok, new_t_state} = save_state(agent_state)
      #       IO.puts "FINIDSHED SAVOING.... #{inspect new_t_state}"
      #       {:reply, {:ok, new_t_state}, new_t_state}

      #     {:error, reason} ->
      #       Logger.error("#{__MODULE__} work cycle failed: #{inspect(reason)}")
      #       {:reply, {:error, reason}, state}
      #   end
      # end

      # def handle_cast({:put_agent_state, map}, state) do
      #   new_state = do_put_agent_state(state, map)
      #   save_state(new_state.data)
      #   {:noreply, new_state}
      # end

      # def handle_cast({:merge_agent_state, map}, state) do
      #   new_state = do_merge_agent_state(state, map)
      #   save_state(new_state.data)
      #   {:noreply, new_state}
      # end

      # def handle_cast({:put_agent_config, map}, state) do
      #   new_state = do_put_agent_config(state, map)
      #   save_state(new_state.data)
      #   {:noreply, new_state}
      # end

      # def handle_cast({:put_working_memory, map}, state) do
      #   new_state = do_put_working_memory(state, map)
      #   save_state(new_state.data)
      #   {:noreply, new_state}
      # end

      # def handle_cast({:put_processing_queue, map}, state) do
      #   new_state = set_processing_queue(state, map)
      #   save_state(new_state.data)
      #   {:noreply, new_state}
      # end

      # def handle_cast({:merge_working_memory, map}, state) do
      #   new_state = do_merge_working_memory(state, map)
      #   save_state(new_state.data)
      #   {:noreply, new_state}
      # end

      # def handle_cast(
      #       {:set_status, new_status},
      #       %Memelex.TidBit{data: %Agent{status: _s} = agent_state} = state
      #     )
      #     when new_status in @valid_statuses do
      #   new_agent_state = %{agent_state | status: new_status}
      #   new_state = %{state | data: new_agent_state}

      #   save_state(new_state.data)

      #   if(new_status == :active) do
      #     schedule_work_loop(new_state)
      #   end

      #   {:noreply, new_state}
      # end

      # def handle_cast(
      #       {:chat_message, message},
      #       state
      #     ) do
      #   {:ok, new_state} = handle_chat_msg(state, message)
      #   {:noreply, new_state}
      # end

      # def handle_cast(
      #       :nudge,
      #       %Memelex.TidBit{data: %Agent{status: :manual}} = state
      #     ) do
      #   Logger.debug("#{__MODULE__} manual nudge...")
      #   send(self(), :work)
      #   {:noreply, state}
      # end

      # def handle_cast(
      #       :nudge,
      #       :inactive = state
      #     ) do
      #   Logger.debug("#{__MODULE__} manual nudge...")
      #   send(self(), :work)
      #   {:noreply, state}
      # end

      #   # do_work(state)
      #   # case do_work(state) do
      #   #   {:ok, ^state} ->
      #   #     IO.puts("NO CHANGE")
      #   #     {:noreply, state}

      #   #   {:ok, %Memelex.TidBit{} = new_state} ->
      #   #     IO.puts("YES CHANGE")
      #   #     # if new_state != state do
      #   #     #   save_state(new_state.data)
      #   #     # end

      #   #     # Logger.debug("#{__MODULE__} work complete.")
      #   #     {:noreply, new_state}

      #   #   {:error, reason} ->
      #   #     Logger.error("#{__MODULE__} failed to do work, #{reason}.")

      #   #     {:noreply, state}
      #   end
      # end

      # def handle_cast(
      #       {:instruction, "compile_sit_rep"},
      #       %Memelex.TidBit{data: %Agent{} = agent} = state
      #     ) do
      #   {:ok, sit_rep} = compile_sit_rep(agent)

      #   new_state = do_merge_agent_state(state, %{"sit_rep" => sit_rep})
      #   save_state(new_state.data)

      #   {:noreply, new_state}
      # end

      # def handle_cast(
      #       {:instruction, instruction},
      #       %Memelex.TidBit{
      #         data: %Agent{
      #           state: %{
      #             "processing_queue" => processing_queue
      #           }
      #         }
      #       } = state
      #     ) do
      #   new_state =
      #     state
      #     |> set_processing_queue(processing_queue ++ [instruction])

      #   {:noreply, new_state}
      # end

      # def handle_cast(
      #       {:seed_system_prompt, prompts},
      #       %Memelex.TidBit{
      #         data: %Agent{
      #           state: %{
      #             "chat_history" => []
      #           }
      #         }
      #       } = state
      #     ) do
      #   new_state =
      #     state
      #     |> add_chat_message(%{"role" => "system", "content" => prompts["sys_prompt"]})
      #     |> add_chat_message(%{"role" => "system", "content" => prompts["instruction_prompt"]})

      #   save_state(new_state.data)

      #   {:noreply, new_state}
      # end

      def handle_cast(:nudge, %Memelex.TidBit{data: %Agent{loop_phase: :perceive} = ag_state} = state) do
        IO.puts "HANDLING NUDGE CALL"
        case perceive(state) do
          {:ok, percepts} ->
            Logger.info "finished perceiving... #{inspect percepts}"
            agent_state = %{ag_state|percepts: percepts, loop_phase: :plan}
            # IO.inspect(agent_state, label: "AG AG AG AG AG")
            {:ok, new_t_state} = save_state(agent_state)
            # IO.puts "FINIDSHED SAVOING.... #{inspect new_t_state}"
            {:noreply, new_t_state}

          {:error, reason} ->
            Logger.error("#{__MODULE__} work cycle failed: #{inspect(reason)}")
            {:noreply, state}
        end
      end

      def handle_cast(:nudge, %Memelex.TidBit{data: %Agent{loop_phase: :plan} = ag_state} = state) do
        IO.puts "HANDLING NUDGE CALL to PLAN"
        case plan(state) do
          {:ok, plans} ->
            # Logger.info "finished perceiving... #{inspect percepts}"
            agent_state = %{ag_state|plans: plans, loop_phase: :act}
            # IO.inspect(agent_state, label: "AG AG AG AG AG")
            {:ok, new_t_state} = save_state(agent_state)
            # IO.puts "FINIDSHED SAVOING.... #{inspect new_t_state}"
            {:noreply, new_t_state}

          {:error, reason} ->
            Logger.error("#{__MODULE__} work cycle failed: #{inspect(reason)}")
            {:noreply, state}
        end
      end

      def handle_cast(:nudge, %Memelex.TidBit{data: %Agent{loop_phase: :act} = ag_state} = state) do
        IO.puts "HANDLING NUDGE CALL to ACT"
        case act(state) do
          {:ok, results} ->
            agent_state = %{ag_state|results: results, loop_phase: :adapt}
            {:ok, new_t_state} = save_state(agent_state)
            {:noreply, new_t_state}

          {:error, reason} ->
            Logger.error("#{__MODULE__} work cycle failed: #{inspect(reason)}")
            {:noreply, state}
        end
      end

      def handle_cast(:nudge, %Memelex.TidBit{data: %Agent{loop_phase: :adapt} = ag_state} = state) do
        IO.puts "HANDLING NUDGE CALL to ADAPT"
        case adapt(state) do
          {:ok, evaluation} ->
            agent_state = %{ag_state|evaluation: evaluation, loop_phase: :perceive}
            {:ok, new_t_state} = save_state(agent_state)
            {:noreply, new_t_state}

          {:error, reason} ->
            Logger.error("#{__MODULE__} work cycle failed: #{inspect(reason)}")
            {:noreply, state}
        end
      end

      def handle_cast(:save, %Memelex.TidBit{data: %Agent{} = agent_state} = state) do
        save_state(agent_state)
        {:noreply, state}
      end


      def handle_cast(:work, %Memelex.TidBit{data: %Agent{status: s} = _agent_s} = state) when s in [:inactive, :paused] do
        Logger.warn "#{__MODULE__} cannot do work as it's inactive."
        {:noreply, state}
      end

      # Core Activation Workflow - FIVE (Framework for Iterative Voluntas Execution)
      def handle_cast(:work, %Memelex.TidBit{data: %Agent{status: :active, loop_phase: :perceive}} = state) do
        case perceive(state) do
          {:ok, percepts} ->
            Logger.info "finished perceiving..."
            save_state(state)
            schedule_work_loop(state)
            {:noreply, %{state|percepts: percepts, loop_phase: :plan}}

          {:error, reason} ->
            Logger.error("#{__MODULE__} work cycle failed: #{inspect(reason)}")
            {:noreply, state}
        end
      end

      def handle_cast(:work, %Memelex.TidBit{data: %Agent{status: :active, loop_phase: :plan}} = state) do
        case plan(state) do
          {:ok, plans} ->
            Logger.info "finished planning..."
            schedule_work_loop(state)
            {:noreply, %{state|plans: plans, loop_phase: :act}}

          {:error, reason} ->
            Logger.error("#{__MODULE__} work cycle failed: #{inspect(reason)}")
            {:noreply, state}
        end
      end

      # act out each plan in it's own work cycle
      def handle_cast(:work, %Memelex.TidBit{data: %Agent{status: :active, plans: [p], loop_phase: :act}} = state) do
        case act(state) do
          {:ok, results} ->
            Logger.info "finished acting..."
            schedule_work_loop(state)
            {:noreply, %{state|results: results, loop_phase: :adapt}}

          {:error, reason} ->
            Logger.error("#{__MODULE__} work cycle failed: #{inspect(reason)}")
            {:noreply, state}
        end
      end

      def handle_cast(:work, %Memelex.TidBit{data: %Agent{status: :active, loop_phase: :adapt}} = state) do
        case adapt(state) do
          {:ok, evaluation} ->
            Logger.info "finished adapting..."
            #TODO here make a log entry for each finished loop
            schedule_work_loop(state)
            {:noreply, %{state|evaluation: evaluation, loop_phase: :perceive}}

          {:error, reason} ->
            Logger.error("#{__MODULE__} work cycle failed: #{inspect(reason)}")
            {:noreply, state}
        end
      end

      def handle_cast(:work, %Memelex.TidBit{data: %Agent{} = agent_s} = state) do
        IO.puts "\n\n\nijwseoijsefoisjefoesijfoesijfesoifj #{inspect agent_s}"
        Logger.debug("#{__MODULE__} can't do work because we're inactive...")
        {:noreply, state}
      end

      # functionally these are the same (handle_info/handle_cast), but it's only possible to 'send' after a timer, not 'cast'
      def handle_info(:work, state) do
        handle_cast(:work, state)
      end

      # def handle_cast(:work, state) do
      #   raise "got work but it's not valid #{inspect state}"
      # end
      # def document_cycle(state)  do
      #   IO.puts "NEED TO DOCUMENT CYCLE"
      #   :cycle_complete
      # end

      # Default Implementations for Workflow Steps
      def perceive(state) do
        Logger.debug("#{__MODULE__}: Perceiving environment...")
        # {:ok, Map.put(state, :beliefs, "default_belief")}
        {:ok, []}
      end

      # def deliberate(state, percepts) do
      #   Logger.debug("#{__MODULE__}: Deliberating tasks...")
      #   {:ok, ["default_task"]}
      # end

      def plan(state) do
        # Logger.debug("#{__MODULE__}: Planning tasks: #{inspect(tasks)}")
        # {:ok, Enum.map(tasks, &{"step_#{&1}", :default_action})}
        {:ok, _no_plans = []}
      end

      def act(state) do
        # Logger.debug("#{__MODULE__}: Executing plans: #{inspect(plans)}")
        {:ok, []}
      end

      def adapt(state) do
        Logger.debug("#{__MODULE__}: (SKIPPING) Adapting based on results...")
        #TODO update log
        {:ok, []}
      end

      # Fallback for unknown instructions
      # def handle_cast({:instruction, unknown}, state) do
      #   Logger.warn("#{__MODULE__}: Unknown instruction: #{inspect(unknown)}")
      #   {:noreply, state}
      # end

      defoverridable perceive: 1, plan: 1, act: 1, adapt: 1


      # def handle_info(:work, %Agent{status: s} = state) do
      #   Logger.warn("#{__MODULE__} has status: #{inspect(s)}, not doing work.")
      #   {:noreply, state}
      # end

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

      # def handle_info(
      #       :work,
      #       %Memelex.TidBit{data: %Agent{status: s}} = state
      #     )
      #     when s in [:active, :manual] do
      #   Logger.debug("#{__MODULE__} doing work...")

      #   case do_work(state) do
      #     {:ok, ^state} ->
      #       Logger.debug("#{__MODULE__} completed work, but no state change")
      #       {:noreply, state}

      #     {:ok, %Memelex.TidBit{} = new_state} ->
      #       IO.puts("YES CHANGE")
      #       # if new_state != state do
      #       #   save_state(new_state.data)
      #       # end

      #       save_state(new_state.data)
      #       schedule_work_loop(new_state)
      #       # Logger.debug("#{__MODULE__} work complete.")
      #       {:noreply, new_state}

      #     # {:ok, new_state} when is_map(new_state) ->
      #     #   # Logger.debug("#{__MODULE__} work complete.")
      #     #   save_state(new_state.data)
      #     #   schedule_work_loop(new_state)
      #     #   {:noreply, new_state}

      #     # {:error, "Error parsing JSON!"} ->
      #     #   Logger.warn("#{__MODULE__} failed to parse JSON. Scheduling work-loop to retry...")
      #     #   schedule_work_loop(state)

      #     #   # TODO need a mechanism for keeping track of retries here... if we dont get JSON after like 5 attempts give up
      #     #   {:noreply, state}

      #     {:error, reason} ->
      #       Logger.error("#{__MODULE__} failed to do work, #{reason}. Scheduling reboot...")

      #       schedule_reboot_attempt()
      #       {:noreply, {:boot_failed, retries: 0}}
      #   end
      # end

      def run_boot_sequence do
        Logger.debug("#{__MODULE__} boot sequence running...")

        case Memelex.My.Wiki.get(%{uuid: uuid()}) do
          {:ok, %Memelex.TidBit{} = agent_t} ->
            Logger.debug("#{__MODULE__} found Agent TidBit: #{inspect(agent_t.title)}")
            {updated_agent_t, _log_tidbit} = find_or_create_log_tidbit(agent_t)
            {:ok, updated_agent_t}

          # random note but - `is_binary` is a terrible name... is_binary should be is_bitstring and
          # is_bitsting should be just `is_bitstream` for what should be, `div8_
          # maybe `is_utf8_string` or `is_octet_bitstring` ? just unfortunate
          {:error, reason} when is_binary(reason) ->
            err = "#{__MODULE__} Boot failed! #{reason}"
            Logger.error(err)
            {:error, err}
        end
      end

      # def do_work(
      #       %Memelex.TidBit{
      #         data: %Agent{state: %{"processing_queue" => ["await_user_response" | _rest]}}
      #       } = state
      #     ) do
      #   # IO.puts("Nothing we can do until we get a response from the user...")

      #   {:ok, state}
      # end

      # def do_work(
      #       %Memelex.TidBit{
      #         data: %Agent{
      #           state: %{
      #             "processing_queue" => ["jsonize_llm_response" | rest]
      #           }
      #         }
      #       } = state
      #     ) do
      #   case jsonize_llm_response(state.data) do
      #     {:ok, %Agent{} = new_data} ->
      #       new_state = %{state | data: new_data}
      #       {:ok, new_state}

      #     {:error, reason} ->
      #       new_state =
      #         state
      #         # retry the JSONize_response instruction
      #         |> set_processing_queue([{"jsonize_llm_response", retry_num: 1}] ++ rest)

      #       {:ok, new_state}
      #   end
      # end

      # @max_jsonize_retries 3
      # def do_work(
      #       %Memelex.TidBit{
      #         data: %Agent{
      #           state: %{
      #             "processing_queue" => [{"jsonize_llm_response", retry_num: n} | rest]
      #           }
      #         }
      #       } = state
      #     )
      #     when n <= @max_jsonize_retries do
      #   case jsonize_llm_response(state.data) do
      #     {:ok, %Agent{} = new_data} ->
      #       new_state = %{state | data: new_data}
      #       {:ok, new_state}

      #     {:error, reason} ->
      #       new_state =
      #         state
      #         # retry the JSONize_response instruction
      #         |> set_processing_queue([{"JSONize_response", retry_num: n + 1}] ++ rest)

      #       {:ok, new_state}
      #   end
      # end

      # def do_work(
      #       %Memelex.TidBit{
      #         data: %Agent{
      #           state: %{
      #             "processing_queue" => [{"jsonize_llm_response", retry_num: n} | rest]
      #           }
      #         }
      #       } = state
      #     )
      #     when n > @max_jsonize_retries do
      #   # TODO record this in the actual log of the Agent state
      #   Logger.error("Failed to JSONize response after #{@max_jsonize_retries} attempts!")

      #   new_state =
      #     state
      #     # give up, need to get the user involved...
      #     |> set_processing_queue(["await_user_response"] ++ rest)

      #   {:ok, new_state}
      # end

      # # If we send the msg `Ack` then remove the "await_user_response" task from the processing queue
      # def handle_chat_msg(
      #       %Memelex.TidBit{
      #         data: %Agent{
      #           state: %{
      #             "processing_queue" => ["await_user_response" | rest]
      #           }
      #         }
      #       } = state,
      #       "Ack"
      #     ) do
      #   IO.puts("Acking msg... continuing processing...")

      #   new_state = state |> set_processing_queue(rest)

      #   {:ok, new_state}
      # end

      # def handle_chat_msg(
      #       %Memelex.TidBit{
      #         data: %Agent{
      #           state: %{"processing_queue" => ["await_user_response" | rest]}
      #         }
      #       } = state,
      #       message
      #     )
      #     when is_binary(message) do
      #   # Put the new User message in the conversation & trigger the LLM to run
      #   new_state =
      #     state
      #     |> add_chat_message(%{"role" => "user", "content" => message})
      #     |> set_processing_queue(["run_llm_analysis"] ++ rest)

      #   {:ok, new_state}
      # end

      # def handle_chat_msg(
      #       %Memelex.TidBit{data: %Agent{}} = state,
      #       message
      #     )
      #     when is_binary(message) do
      #   # Put the new User message in the conversation & trigger the LLM to run
      #   new_state =
      #     state
      #     |> add_chat_message(%{"role" => "user", "content" => message})

      #   {:ok, new_state}
      # end

      # def nudge do
      #   GenServer.cast(__MODULE__, :nudge)
      # end

      # Injected functions or defaults can go here.
      # For example, a default implementation for terminate:
      # def terminate(_reason, _state), do: :ok

      # TODO this updates the memex but it doesnt cause a refresh of the agent! The agent will still have the old state until we restart the memex if we dont fix this!!
      def save_state(%Agent{} = new_state) do
        # t = tidbit()
        # new_data = %{t.data | state: state}
        Memelex.My.Wiki.update(tidbit(), %{data: new_state})
      end

      # TODO this updates the memex but it doesnt cause a refresh of the agent! The agent will still have the old state until we restart the memex if we dont fix this!!
      def save_agent_state(agent_state) when is_map(agent_state) do
        t = tidbit()
        new_data = %{t.data | state: agent_state}
        Memelex.My.Wiki.update(tidbit(), %{data: new_data})
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

      def find_or_create_log_tidbit(%Memelex.TidBit{meta: []} = agent_t) do
        Logger.debug(
          "#{__MODULE__} no log found for agent #{inspect(agent_t.title)}, creating one now..."
        )

        create_new_log_tidbit(agent_t)
      end

      # TODO handle cases where there is more stuff in the meta for a particular tidbit, maybe shouldn't use meta for this at all...
      def find_or_create_log_tidbit(
            %Memelex.TidBit{meta: [%{"logfile_uuid" => logfile_uuid}]} = agent_t
          )
          when is_binary(logfile_uuid) do
        case Memelex.My.Wiki.get(logfile_uuid) do
          {:ok, %Memelex.TidBit{} = log_t} ->
            Logger.debug("#{__MODULE__} found #{log_t.title}")
            {agent_t, log_t}

          {:error, reason} ->
            raise "Expected #{agent_t.title} to have a log TidBit with uuid #{logfile_uuid}, but we couldn't find one.\n\n#{inspect(reason)}"
        end
      end

      def create_new_log_tidbit(%Memelex.TidBit{} = agent_t) do
        # TODO use linking here probably
        # this saves the new log tidbit in the DB, we also
        log_t =
          Memelex.My.Wiki.new(%{
            title: "Log for #{agent_t.title}",
            type: {:external, :textfile},
            tags: [tag()],
            # data: {:filepath, agent_log_filepath(agent_t)},
            data: %{"file_path" => agent_log_filepath(agent_t)},
            meta: [%{"agent_uuid" => agent_t.uuid}]
          })

        # now update the original agent TidBit
        # need to return the updated agent because when we make a new logfile we update this tidbit too
        # {updated_agent_t, log_t} = add_logfile_tidbit_to_meta(agent_t, log_t)
        updated_agent_t = add_logfile_tidbit_to_meta(agent_t, log_t)

        {updated_agent_t, log_t}
        # add_logfile_tidbit_to_meta(agent_t, log_t)
      end

      # OpenAI.chat_completion(
      #       model: "o1-preview",
      #       messages: [
      #         # %{"role" => "system", "content" => agent.state["sys_prompt"]},
      #         %{"role" => "system", "content" => PromptLib.sys_prompt(:auto_ceo)},
      #         # %{role: "system", content: "Your task today is to provide a \"Sit-Rep\" or Situation-Report based on the current state of the Autonomous agent. You need to highlight what's important, where we're at & what should happen next."},
      #         %{"role" => "system", "content" => PromptLib.instruction_prompt(:jsonize_text)},
      #         # %{role: "user", content: "Please provide a sit-rep based on this state:\n\n#{inspect(agent.state)}"}
      #         %{"role" => "user", "content" => PromptLib.user_prompt(:jsonize_text, text)}
      #       ]
      #     )


      # def compile_sit_rep(%Agent{state: agent_state} = agent) do
      #   sit_rep = do_run_llm_analysis(:compile_sit_rep, agent)
      #   {:ok, sit_rep}
      # end

      # def jsonize_llm_response(
      #       %Agent{
      #         config: %{"llm_engine" => ["open_ai", "gpt4"]},
      #         state: %{"working_memory" => %{"last_llm_response" => text}}
      #       } = agent
      #     )
      #     when is_binary(text) do
      #   {:ok, %{choices: [%{"message" => %{"content" => response}}]}} =
      #     OpenAI.chat_completion(
      #       model: "gpt-4",
      #       messages: [
      #         # %{"role" => "system", "content" => agent.state["sys_prompt"]},
      #         %{"role" => "system", "content" => PromptLib.sys_prompt(:auto_ceo)},
      #         # %{role: "system", content: "Your task today is to provide a \"Sit-Rep\" or Situation-Report based on the current state of the Autonomous agent. You need to highlight what's important, where we're at & what should happen next."},
      #         %{"role" => "system", "content" => PromptLib.instruction_prompt(:jsonize_text)},
      #         # %{role: "user", content: "Please provide a sit-rep based on this state:\n\n#{inspect(agent.state)}"}
      #         %{"role" => "user", "content" => PromptLib.user_prompt(:jsonize_text, text)}
      #       ]
      #     )

      #   case Jason.decode(response) do
      #     {:ok, jsonified_response} ->
      #       new_agent =
      #         agent
      #         |> do_merge_agent_state(%{
      #           "jsonified_response" => jsonified_response
      #         })

      #       {:ok, new_agent}

      #     {:error, reason} ->
      #       {:error, reason}
      #   end
      # end


#   def do_put_agent_state(
#     %Memelex.TidBit{data: %Agent{} = agent} = state,
#     new_state
#   ) do
# new_agent = %{agent | state: new_state}
# %{state | data: new_agent}
# end

# def do_merge_agent_state(
#       %Memelex.TidBit{data: %Agent{state: agent_state} = agent} = state,
#       map
#     ) do
#   new_agent_state = Map.merge(agent_state, map)
#   new_agent = %{agent | state: new_agent_state}
#   %{state | data: new_agent}
# end

# def do_merge_agent_state(
#     %Agent{state: agent_state} = agent,
#     map
#   ) do
# new_working_memory = Map.merge(agent_state["working_memory"], map)
# new_agent_state = Map.put(agent_state, "working_memory", new_working_memory)
# %{agent | state: new_agent_state}
# end

# # over-write the current agent config with a new config
# def do_put_agent_config(
#     %Memelex.TidBit{data: %Agent{} = agent} = state,
#     new_config
#   ) do
# new_agent = %{agent | config: new_config}
# %{state | data: new_agent}
# end

# # over-write the current agent working-memory
# def do_put_working_memory(
#     %Memelex.TidBit{data: %Agent{state: agent_state} = agent} = state,
#     new_working_memory
#   ) do
# new_agent_state = Map.put(agent_state, "working_memory", new_working_memory)
# new_agent = %{agent | state: new_agent_state}
# new_state = %{state | data: new_agent}

# new_state
# end

# def do_put_processing_queue(
#       %Memelex.TidBit{data: %Agent{state: agent_state} = agent} = state,
#       new_processing_queue
#     )
#     when is_list(new_processing_queue) do
#   new_agent_state = Map.put(agent_state, "processing_queue", new_processing_queue)
#   new_agent = %{agent | state: new_agent_state}
#   new_state = %{state | data: new_agent}

#   new_state
# end

# def do_merge_working_memory(
#     %Memelex.TidBit{data: %Agent{state: agent_state} = agent} = state,
#     new_working_memory
#   )
#   when is_map(new_working_memory) do
# case Map.get(agent_state, "working_memory") do
#   nil ->
#     new_agent_state = Map.put(agent_state, "working_memory", new_working_memory)
#     new_agent = %{agent | state: new_agent_state}
#     new_state = %{state | data: new_agent}

#     new_state

#   current_working_memory when is_map(current_working_memory) ->
#     new_agent_state = Map.merge(current_working_memory, new_working_memory)
#     new_agent = %{agent | state: new_agent_state}
#     new_state = %{state | data: new_agent}

#     new_state
# end
# end




  # # Over-write whatever is in the current processing-queue with a new queue.
  # # TODO set up multiple processing queues, maybe one for each focus?
  # def set_processing_queue(
  #       %Memelex.TidBit{
  #         data: %Agent{state: agent_state} = agent
  #       } = state,
  #       new_queue
  #     )
  #     when is_list(new_queue) do
  #   new_agent_state = Map.put(agent_state, "processing_queue", new_queue)
  #   new_agent = %{agent | state: new_agent_state}
  #   new_state = %{state | data: new_agent}

  #   new_state
  # end

  # # appends a new User chat message to the chat history
  # def add_chat_message(state, message) when is_binary(message) do
  #   add_chat_message(state, %{"role" => "user", "content" => message})
  # end

  # def add_chat_message(
  #       %Memelex.TidBit{
  #         data: %Agent{state: %{"chat_history" => chat_history} = agent_state} = agent
  #       } = state,
  #       %{"role" => _r, "content" => _content} = new_msg
  #     )
  #     when is_list(chat_history) do
  #   # new_msg_map = %{"role" => "user", "content" => new_msg}
  #   new_chat_history = chat_history ++ [new_msg]
  #   new_agent_state = Map.put(agent_state, "chat_history", new_chat_history)
  #   new_agent = %{agent | state: new_agent_state}
  #   new_state = %{state | data: new_agent}

  #   new_state
  # end

  # def add_chat_message(state, %{"role" => "user", "content" => content}) do
  #   add_chat_message(state, content)
  # end

  # # puts the task "await_user_response" on the top of the processing queue,
  # # so that the next time the agent is run, it will wait for the user to respond
  # def await_user_response(
  #       %Memelex.TidBit{
  #         data:
  #           %Agent{
  #             state: %{"processing_queue" => processing_queue} = agent_state
  #           } = agent
  #       } = state
  #     ) do
  #   new_processing_queue = ["await_user_response"] ++ processing_queue
  #   new_agent_state = Map.put(agent_state, "processing_queue", new_processing_queue)
  #   new_agent = %{agent | state: new_agent_state}
  #   new_state = %{state | data: new_agent}

  #   new_state
  # end

  # def run_llm_analysis(
  #       %Memelex.TidBit{
  #         data: %Agent{state: %{"chat_history" => chat_history} = agent_state}
  #       } = state
  #     )
  #     when is_list(chat_history) do
  #   # TODO lol don't do it this way obviously
  #   {:ok, response_1} = query_open_ai(state)
  #   {:ok, response_2} = query_open_ai(state)
  #   {:ok, response_3} = query_open_ai(state)

  #   responses = [response_1, response_2, response_3]

  #   {:ok, summarized_response} = do_summarize_responses(state, responses)

  #   new_working_memory =
  #     Map.merge(agent_state["working_memory"], %{
  #       "last_llm_response" => summarized_response
  #     })

  #   new_chat_history =
  #     agent_state["chat_history"] ++ [%{"role" => "assistant", "content" => summarized_response}]

  #   new_agent_state =
  #     agent_state
  #     |> Map.put("working_memory", new_working_memory)
  #     |> Map.put("chat_history", new_chat_history)

  #   new_agent = state.data |> Map.put(:state, new_agent_state)
  #   _new_state = %{state | data: new_agent}
  # end






  # def query_open_ai(%{
  #       "sys_prompt" => sys_prompt,
  #       "instruction_prompt" => instruction_prompt,
  #       "messages" => messages
  #     })
  #     when is_list(messages) do
#     def query_open_ai(
#       %Memelex.TidBit{
#         data: %Agent{
#           config: %{"llm_engine" => ["open_ai", "gpt4"]},
#           state: %{"chat_history" => chat_history}
#         }
#       } = state
#     )
#     when is_list(chat_history) do
#   {:ok, %{choices: [%{"message" => %{"content" => llm_response}}]}} =
#     OpenAI.chat_completion(
#       model: "gpt-4",
#       messages: chat_history
#     )

#   {:ok, llm_response}
# end

def tag(%{name: name}) do
  String.downcase(name)
end

def initial_log(agent_t) do
  ~s|Initial log for #{agent_t.title}\n\n#{inspect(agent_t.data)}\n\n===\n\n|
end

@five_seconds :timer.seconds(5)
def schedule_reboot_attempt do
  schedule_reboot_attempt(@five_seconds)
end

@default_work_loop_period :timer.seconds(3)
def schedule_reboot_attempt(timer) do
  Process.send_after(self(), :reboot, timer)
end

# def schedule_work_loop(%Memelex.TidBit{status: :active}) do
#   # we can optionally declare `@loop_timer` in the using module
#   # Process.send_after(self(), :work, @default_work_loop_period)
# end

def schedule_work_loop(_agent_t) do
  Process.send_after(self(), :work, :timer.seconds(3))
end

# def schedule_work_loop(_state) do
#   Logger.debug("#{__MODULE__} does not have `:active` status, not scheduling work loop.")
#   nil
# end

def add_logfile_tidbit_to_meta(%Memelex.TidBit{} = agent_t, log_t) do
  Memelex.My.Wiki.update(agent_t, {:add_meta, %{"logfile_uuid" => log_t.uuid}})
end


# defp do_run_llm_analysis(
#   :compile_sit_rep,
#   %Agent{config: %{"llm_engine" => ["open_ai", "gpt4"]}} = agent
# ) do
# sys_prompt = agent.state["sys_prompt"]
# instruction_prompt = PromptLib.instruction_prompt(:compile_sit_rep, agent)
# user_prompt = PromptLib.user_prompt(:compile_sit_rep, agent)

# {:ok, %{choices: [%{"message" => %{"content" => response}}]}} =
# OpenAI.chat_completion(
#  model: "gpt-4",
#  messages: [
#    %{"role" => "system", "content" => sys_prompt},
#    %{"role" => "system", "content" => instruction_prompt},
#    %{"role" => "user", "content" => user_prompt}
#  ]
# )

# response
# end

  # TODO move this into prompt lib...
  def do_summarize_responses(state, responses) do
    summarizer_instruction_prompt = """
    Right now I need you to read, compare, analyze, contrast, summarize (thoroughly, taking all possible ideas, concepts & pieces of information into account) and whatever else you think is necessary,
    and then synthesize the following responses into a single, coherent, concise, accurate, and complete summary.

    The idea is that by querying the LLM multiple times & then once more to summarize etc, then we will get a better result.

    Don't reply like a summarizer though - I just want you take into account all the previous responses, and turn them into a single, coherent, concise, accurate, and complete answer to the original query.
    """

    summarizer_user_prompt = """
    Please provide your summary to the following previous LLM responses.

    ```
    === previous LLM prompt ===
    #{inspect(state.data.state["instruction_prompt"])}
    ```

    The responses were:

    ```
    #{Enum.map(responses, &("=== previous LLM response ===" <> &1))}
    ```
    """

    {:ok, %{choices: [%{"message" => %{"content" => llm_response}}]}} =
      OpenAI.chat_completion(
        model: "gpt-4",
        messages: [
          # %{role: "system", content: state.data.state["sys_prompt"]},
          %{role: "system", content: summarizer_instruction_prompt},
          %{role: "user", content: summarizer_user_prompt}
        ]
      )

    {:ok, llm_response}
  end

      # def do_work(
      #       %Memelex.TidBit{
      #         data: %Agent{state: %{"processing_queue" => []}}
      #       } = state
      #     ) do
      #   # Switch focus here? Since we're out of engineering tasks?
      #   # TODO eventually we could have users respond to specific threads & continue others while we wait

      #   # IO.puts("#{__MODULE__} doing work... (engineering focus, no tasks)")
      #   IO.puts("Nothing to do!!")

      #   # new_state =
      #   #   state
      #   #   |> set_processing_queue(["brainstorm_tasks"])

      #   # {:ok, new_state}
      #   {:ok, state}
      # end

      # def do_work(
      #       %Memelex.TidBit{
      #         data: %Agent{state: %{"processing_queue" => ["run_llm_analysis" | rest]}}
      #       } = state
      #     ) do
      #   IO.puts("#{__MODULE__} doing work... (running LLM analysis)")

      #   new_state =
      #     state
      #     |> run_llm_analysis()
      #     |> set_processing_queue(rest)

      #   # TODO eventually we could have users respond to specific threads & continue others while we wait

      #   {:ok, new_state}
      # end

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

      # def handle_instruction(state, unknown_instruction) do
      #   Logger.error("Recv'd unknown instruction: #{inspect(unknown_instruction)}")
      #   {:ok, state}
      # end

      # def do_work(state) do
      #   IO.puts("#{__MODULE__} fucked up!!")

      #   IO.inspect(state)
      #   {:ok, state}
      # end



    end
  end
end

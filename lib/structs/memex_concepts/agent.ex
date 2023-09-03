defmodule Memelex.Lib.Structs.MemexConcepts.Agent do
  @moduledoc """
  Represents an Agent within the Memex framework.

  An Agent is an autonomous entity that can process, organize, or retrieve information
  within the Memex system. It might interact with low-level memory structures (LLMs)
  or other Agents, and can be tasked with various operations.

  ## Fields

  - `name`: A human-readable name or title for the Agent.
  - `status`: Indicates the current status of the Agent (e.g., active, dormant, error).
  - `last_activity`: Timestamp of the last activity performed by the Agent.
  - `config`: Configuration or settings specific to this Agent's operation.
  """

  @type status :: :active | :dormant | :error

  # need to be able to captyure agents which are GenServers, and those which are powered by LLMs,
  # and for those types what the prompt is etc...

  @type t :: %__MODULE__{
          name: String.t(),
          status: status(),
          last_activity: DateTime.t(),
          config: map()
        }

  defstruct [
    :name,
    :status,
    :last_activity,
    :config
  ]

  # NOTE this has to go *after* we've defined the struct
  use Memelex.Utils.JsonEncodable

  # TODO remove this when FileIO line 130 changes to checking for a `new` function rather than `construct`
  def construct(args) do
    new(args)
  end

  def new(%{"name" => name} = args) do
    config =
      case args["config"] do
        nil ->
          %{}

        cfg_with_mfa = %{"mfa" => [mod, fun, args]} ->
          Map.put(
            cfg_with_mfa,
            "mfa",
            # we might need to only use `to_atom` in the future, if we haven't
            # loaded a particular struct yet (maybe we should do that first??)
            {String.to_existing_atom(mod), String.to_existing_atom(fun), args}
          )

        cfg when is_map(cfg) ->
          cfg
      end

    %__MODULE__{
      name: name,
      status: :active,
      last_activity: DateTime.utc_now(),
      config: config
    }
  end

  # def add_to_memex(%__MODULE__{} = agent) do
  #   # Memelex.WikiServer.add_agent(agent)
  # end

  # def new(params) do
  #   valid_params =
  #     params
  #     |> Map.merge(%{last_activity: Memelex.My.current_time() |> DateTime.to_unix()})
  #     |> Memelex.Utils.ToolBag.generate_uuid()

  #   Kernel.struct(__MODULE__, valid_params |> convert_to_keyword_list())
  # end
end

defmodule Memelex.Lib.Structs.MemexConcepts.V01.Agent do
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

  @type status :: :active | :inactive | :error | :paused

  # need to be able to captyure agents which are GenServers, and those which are powered by LLMs,
  # and for those types what the prompt is etc...

  @type t :: %__MODULE__{
          name: String.t(),
          status: status(),
          last_activity: DateTime.t(),
          config: map(),
          boot_seq: list(any()) | nil,
          cache: list(any()) | nil,
          log_tidbit_uuid: String.t()
        }

  defstruct [
    :name,
    :status,
    :last_activity,
    :config,
    :boot_seq,
    :cache,
    :log_tidbit_uuid
  ]

  # NOTE this has to go *after* we've defined the struct
  use Memelex.Utils.JsonEncodable

  def new(%{"name" => name} = args) when is_binary(name) do
    name = to_camel_case(name)

    %__MODULE__{
      name: name,
      status: :active,
      last_activity: DateTime.utc_now(),
      config: agent_config(args),
      boot_seq: Map.get(args, "boot_seq") || nil
    }
  end

  defp agent_config(args) do
    case Map.get(args, "config") do
      nil ->
        %{}

      %{"mfa" => [mod, fun, args]} = config_with_mfa ->
        # override the `mfa` list-of-strings with a normal MFA tuple
        Map.put(
          config_with_mfa,
          "mfa",
          # should be able to use `to_existing_atom` because Agent structs should have been loaded by now...
          {String.to_existing_atom(mod), String.to_existing_atom(fun), args}
        )

      config_without_mfa when is_map(config_without_mfa) ->
        config_without_mfa
    end
  end

  defp to_camel_case(string) do
    string
    |> String.split(~r/[^a-zA-Z0-9]+/)
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join("")
  end
end

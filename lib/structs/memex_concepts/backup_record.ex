defmodule Memelex.BackupRecord do
  @enforce_keys [:uuid, :timepoint, :version]

  @derive Jason.Encoder

  defstruct [
    # we require UUIDs for precision when pattern-matching
    uuid: nil,
    # If the user wants to leave any special text data for this backup, leave it here
    label: nil,
    # The DateTime, stored in unix format, of when we made this backup
    timepoint: nil,
    # usually we version backups by date, but if we take multiples on the same day, we use this to keep track. e.,g. "01", "02", "14", etc
    version: nil,
    # take a hash of the entire backup #TODO
    hash: nil,
    # where the backup is stored
    location: nil,
    # this allows us to reconstruct the correct Elixir struct from the JSON text files
    module: __MODULE__
  ]

  def new(params) do
    valid_params =
      params
      |> Map.merge(%{timepoint: Memelex.My.current_time() |> DateTime.to_unix()})
      |> Memelex.Utils.ToolBag.generate_uuid()

    Kernel.struct(__MODULE__, valid_params |> convert_to_keyword_list())
  end

  def convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    # keys are already atoms in this case
    map |> Keyword.new(fn {k, v} -> {k, v} end)
  end
end

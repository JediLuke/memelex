defmodule Memelex.BackupRecord do

  @enforce_keys [:uuid, :timepoint, :version]

  @derive Jason.Encoder

  defstruct [

      uuid:      nil,          # we require UUIDs for precision when pattern-matching
      label:     nil,          # If the user wants to leave any special text data for this backup, leave it here
      timepoint: nil,          # The DateTime, stored in unix format, of when we made this backup
      version:   nil,          # usually we version backups by date, but if we take multiples on the same day, we use this to keep track. e.,g. "01", "02", "14", etc
      hash:      nil,          # take a hash of the entire backup #TODO
      location:  nil,          # where the backup is stored

      module:    __MODULE__    # this allows us to reconstruct the correct Elixir struct from the JSON text files
  ]


  def construct(params) do
    
    valid_params = 
      params
      |> Map.merge(%{timepoint: Memelex.My.current_time() |> DateTime.to_unix()})
      |> Memelex.Utils.ToolBag.generate_uuid()

    Kernel.struct(__MODULE__, valid_params |> convert_to_keyword_list())
  end

  def convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    map |> Keyword.new(fn {k,v} -> {k,v} end) #keys are already atoms in this case
  end


end
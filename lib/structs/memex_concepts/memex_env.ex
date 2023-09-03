defmodule Memelex.Lib.Structs.MemexConcepts.MemexEnv do
  defstruct [
    # Owner's name or identifier
    :owner,
    # Name of the memex
    :name,
    # Date when the memex was created
    :created_at,
    # Any additional metadata or settings for the memex
    :metadata,
    # The Elixir module defined as the root of the custom elixir/memex env
    :my_modz,
    # The path to the directory where the memex' raw data is saved
    :memex_directory,
    # The path to the directory where the memex' backups are saved
    :backups_directory
  ]

  require Logger

  def new(%{name: name, memex_directory: memex_env_directory}) do
    %__MODULE__{
      name: name,
      memex_directory: memex_env_directory,
      created_at: DateTime.utc_now()
    }
  end
end

# # A list or map of personal notes
# :notes,
# # A list or map of bookmarks or favorite links
# :bookmarks,
# # A list or map of personal documents
# :documents,
# # A list or map of personal contacts
# :contacts,
# # A list or map of tasks or to-dos
# :tasks,

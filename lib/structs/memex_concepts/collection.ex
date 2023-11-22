defmodule Memelex.Lib.Structs.MemexConcepts.V01.Collection do
  @moduledoc """
  Represents a curated collection within the Memex.

  Collections are flexible and dynamic groupings of TidBits, which may represent various themes, projects, or concepts. Each collection is an organized aggregation of items, which can belong to multiple collections and have complex relationships.

  ## Fields:

  - `name`: The name or title of the collection.
  - `description`: A brief overview or summary of the collection.
  - `type`: The type of collection (e.g., Book, Project, Playlist).
  - `items`: A list of references to TidBits or other collections included in this collection.
  - `relationships`: Describes the relationships between this collection and other collections or TidBits.
  - `curator`: Information about who is curating or managing the collection.
  - `metadata`: Additional information about the collection, such as creation date, tags, thematic connections, etc.
  """

  @derive Jason.Encoder

  @valid_types ["ordered_list", "tag_heirarchy", "computed"]

  defstruct name: nil,
            description: nil,
            type: nil,
            items: [],
            relationships: %{},
            curator: nil,
            metadata: %{}

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          type: String.t(),
          items: [TidBit.t() | t()],
          relationships: map(),
          curator: String.t() | nil,
          metadata: map()
        }

  def new(%{"name" => name} = args) when is_binary(name) do
    %__MODULE__{
      name: name,
      description: args["description"],
      type: "ordered_list"
    }
  end
end

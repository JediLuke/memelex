defmodule Memelex.Lib.Structs.ConceptLib.Book do
  @moduledoc """
  Represents a Book within the Memex framework.

  A Book is a structured representation of a literary or informational work, capturing both its general attributes and specific metadata that might be relevant within the context of the memex.

  ## Fields

  - `title`: The title of the book.
  - `authors`: A list of authors associated with the book.
  - `publication_date`: The date when the book was published.
  - `genres`: A list of genres or categories associated with the book.
  - `summary`: A brief summary or description of the book.
  - `tags`: Custom tags or keywords associated with the book.
  - `status`: Indicates if the book is read, unread, owned, etc.
  - `notes`: Personal notes or annotations about the book.
  """

  @type status :: :read | :unread | :owned | :wishlist | :borrowed

  @type t :: %__MODULE__{
          title: String.t(),
          authors: list(String.t()),
          publication_date: Date.t(),
          genres: list(String.t()),
          summary: String.t() | nil,
          tags: list(String.t()),
          status: status(),
          notes: String.t() | nil
        }

  defstruct [
    :title,
    :authors,
    :publication_date,
    :genres,
    :summary,
    :tags,
    :status,
    :notes
  ]
end

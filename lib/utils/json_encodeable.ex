defmodule Memelex.Utils.JsonEncodable do
  @moduledoc """
  Memex.JsonEncodable

  A module that provides a macro to automatically implement the `Jason.Encoder` protocol
  for a given struct, enabling it to be converted into JSON format.

  ## Usage

  To make a struct JSON encodable:

      defmodule YourStructModule do
        use Memex.JsonEncodable

        defstruct [
          # ... your fields ...
        ]
      end

  After this, you'll be able to use `Jason.encode/1` or any other JSON encoding function
  on instances of `YourStructModule`.

  ## How it Works

  The macro injects an implementation of the `Jason.Encoder` protocol for the struct,
  converting the struct to a map and then encoding that map to JSON.

  """

  defmacro __using__(_) do
    # Capture the calling module
    caller_module = __CALLER__.module

    quote do
      # Implement the Jason.Encoder protocol for the captured module's struct
      defimpl Jason.Encoder, for: unquote(caller_module) do
        def encode(%unquote(caller_module){} = struct, opts) do
          map = Map.from_struct(struct)
          Jason.Encode.map(map, opts)
        end
      end
    end
  end
end

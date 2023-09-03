defmodule Memelex.Utils.FileIO do
  require Logger

  ## Maps

  @doc ~s(Open a file and interpret it as a Map.)
  def readmap(filepath) when is_bitstring(filepath) do
    case File.read(filepath) do
      {:ok, ""} ->
        # empty files == empty Map
        %{}

      {:ok, data} ->
        data |> Jason.decode!()

      {:error, reason} ->
        context = %{reason: reason, filepath: filepath}
        {:error, context}
    end
  end

  @doc ~s(Writes a map to, and even overwrites!, a file.)
  def writemap(filepath, data) when is_map(data) do
    # TODO how do we encode atoms? Do they come back out as atoms?? I think my atoms are becoming text during the save...
    write(filepath, Jason.encode!(data))
  end

  ## MapLists

  @doc ~s(Use this function to open files which have a list of maps, e.g. TidbitDB)
  def read_maplist(filepath) when is_bitstring(filepath) do
    case File.read(filepath) do
      {:ok, ""} ->
        # empty file == empty List
        []

      {:ok, data} ->
        data |> Jason.decode!() |> convert_to_structs()

      {:error, reason} ->
        context = %{reason: reason, filepath: filepath}
        {:error, context}
    end
  end

  def read_maplist(filepath, encrypted?: true, key: key) when is_bitstring(filepath) do
    case File.read(filepath) do
      {:ok, ""} ->
        # empty file == empty List
        []

      {:ok, data} ->
        case Memelex.Utils.Encryption.decrypt(data, key) do
          :error ->
            Logger.warn("Fetch passwords failed!")
            []

          data when is_bitstring(data) ->
            Jason.decode!(data)
            |> convert_to_structs()

            # _empty_list = [] ->
            #     []
            # [_map = %{}|_rest] = maplist ->
            #     # a list of at least one map
            #     maplist
            #     |> Jason.decode!()
            #     |> convert_to_structs()
        end

      {:error, reason} ->
        context = %{reason: reason, filepath: filepath}
        {:error, context}
    end
  end

  @doc ~s(Writes a list of maps, or even overwrites!, to a file.)
  def write_maplist(filepath, data)
      when is_bitstring(filepath) and is_list(data) do
    write(filepath, Jason.encode!(data))
  end

  def write_maplist(filepath, data, encrypted?: true, key: key)
      when is_bitstring(filepath) and is_list(data) do
    encrypted_data = data |> Jason.encode!() |> Memelex.Utils.Encryption.encrypt(key)

    write(filepath, encrypted_data)
  end

  ## Utils

  def write(filepath, data) when is_map(data) or is_list(data) do
    write(filepath, Jason.encode!(data))
  end

  def write(filepath, data) when is_bitstring(filepath) and is_binary(data) do
    {:ok, file} = File.open(filepath, [:write])
    :ok = IO.binwrite(file, data)
    :ok = File.close(file)
  end

  def convert_to_structs(list_of_maps) do
    list_of_maps
    |> convert_whole_list_to_tidbit_structs()
    |> structify_data()
  end

  def convert_whole_list_to_tidbit_structs(list) do
    list
    |> Enum.map(fn map_with_string_keys ->
      struct_params = map_with_string_keys |> convert_to_keyword_list()
      Kernel.struct(Memelex.TidBit, struct_params)
    end)
  end

  def structify_data(list) do
    list
    |> Enum.map(fn
      %Memelex.TidBit{type: ["struct", _struct_mod]} = t ->
        structify_tidbit(t)

      any_non_struct_tidbit ->
        # pass through unchanged
        any_non_struct_tidbit
    end)
  end

  def structify_tidbit(%Memelex.TidBit{type: ["struct", struct_mod_string], data: data} = t)
      when is_bitstring(struct_mod_string) do
    # sometimes we get a transient error where it couldn't decode a memex, so I'm trying this...
    {:module, struct_mod} =
      String.to_existing_atom(struct_mod_string)
      |> Code.ensure_loaded()

    if function_exported?(struct_mod, :construct, 1) do
      # use constructor, to validate incoming data
      structified_data = struct_mod.construct(data)

      if not is_struct(structified_data) do
        raise "structified data is not a struct: #{inspect(structified_data)}"
      end

      %{t | type: ["struct", struct_mod], data: structified_data}
    else
      # TODO maybe we just skip & log it as a failed tidbit??
      Logger.error("Failed to open TidBit - #{inspect(t)}")

      raise "unable to interpret struct TidBit for: #{inspect(struct_mod)}\n\nDid not export the `construct` function.\n"
    end
  end

  defp convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    # TODO figure out how to use `to_existing_atom` here (maybe? Maybe not worth it? just don't blow up the atom table :D)
    map |> Keyword.new(fn {k, v} -> {String.to_atom(k), v} end)
  end
end

env = %{
  backups_directory: "/home/luke/memex/backups/Rob",
  memex_directory: "/home/luke/memex/Rob",
  my_modz: :Rob,
  name: "Rob"
}

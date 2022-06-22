defmodule Memelex.Utils.FileIO do
  require Logger


  ## Maps


  @doc ~s(Open a file and interpret it as a Map.)
  def readmap(filepath) when is_bitstring(filepath) do
    case File.read(filepath) do
      {:ok, ""}   ->
         %{} # empty files == empty Map
      {:ok, data} ->
         data |> Jason.decode!()
      {:error, reason} ->
         context = %{reason: reason, filepath: filepath}
         {:error, context}
    end
  end

  @doc ~s(Writes a map to, and even overwrites!, a file.)
  def writemap(filepath, data) when is_map(data) do
    write(filepath, Jason.encode!(data)) #TODO how do we encode atoms? Do they come back out as atoms?? I think my atoms are becoming text during the save...
  end


  ## MapLists


  @doc ~s(Use this function to open files which have a list of maps, e.g. TidbitDB)
  def read_maplist(filepath) when is_bitstring(filepath) do
    case File.read(filepath) do
      {:ok, ""}   ->
        [] # empty files == empty List
      {:ok, data} ->
        data |> Jason.decode!() |> convert_to_structs()
      {:error, reason} ->
         context = %{reason: reason, filepath: filepath}
         {:error, context}
    end
  end

  def read_maplist(filepath, [encrypted?: true, key: key]) when is_bitstring(filepath) do
    case File.read(filepath) do
      {:ok, ""} ->
         [] # empty files == empty List
      {:ok, data} ->
        case Memelex.Utils.Encryption.decrypt(data, key) do
          :error ->
              Logger.warn "Fetch passwords failed!"
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

  def write_maplist(filepath, data, [encrypted?: true, key: key])
    when is_bitstring(filepath) and is_list(data) do
      encrypted_data =
        data |> Jason.encode!() |> Memelex.Utils.Encryption.encrypt(key)

      write(filepath, encrypted_data)
  end


  ## Utils


  def write(filepath, data) when is_bitstring(filepath) and is_binary(data) do
    {:ok, file} = File.open(filepath, [:write])
    file |> IO.binwrite(data)
    :ok = File.close(file)
  end

  # each entry in the maplist ought to have a Struct it can map to
  def convert_to_structs(list_of_maps) do
    _a = Memex.TidBit
    list_of_maps
    |> Enum.map(
         fn(map_with_string_keys) ->
              struct_params = map_with_string_keys |> convert_to_keyword_list()
              struct_module =
                #TODO temporary workaround for migrating types of struct
                if struct_params[:module] == "Elixir.Memex.TidBit" do
                  Memelex.TidBit
                else
                  struct_params[:module] |> String.to_existing_atom()
                end
              Kernel.struct(struct_module, struct_params)
         end 
         )
    # |> Enum.map(
    #      fn
    #        %Memelex.TidBit{}  = t ->
    #             # if the TidBit contains a Struct in it's data field, we want to reconstruct it here 
    #             case t.data do
    #               %{"module" => "Memex.Person"} ->
    #                 Logger.warn "Found an old TidBit type..."
    #                 new_data = Kernel.struct(Memelex.Person, t.data |> convert_to_keyword_list())
    #                 t |> Map.merge(%{data: new_data})
    #               %{"module" => mod} ->
    #                 new_data = Kernel.struct(String.to_atom(mod), t.data |> convert_to_keyword_list())
    #                 t |> Map.merge(%{data: new_data})
    #               _else ->
    #                   t
    #             end
          
    #        #TODO probably should be ONLY TidBits, dont have multiple types of struct in the Memex
    #        other ->
    #             Logger.warn "FOund something weird in the memex: #{inspect other}"
    #             other
    #      end
    #      )
  end

  defp convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    map |> Keyword.new(fn {k,v} -> {String.to_atom(k),v} end) #TODO figure out how to use `to_existing_atom` here (maybe? Maybe not worth it? just don't blow up the atom table :D)
  end
end
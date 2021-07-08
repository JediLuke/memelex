defmodule Memex.Utils.FileIO do

  @doc ~s(Open a file and interpret it as a Map.)
  def readmap(fp) when is_bitstring(fp) do
    case File.read(fp) do
      {:ok, ""}   -> %{} # empty files == empty Map
      {:ok, data} -> data |> Jason.decode!()
    end
  end

  @doc ~s(Writes a map to, and even overwrites!, a file.)
  def writemap(fp, data) when is_map(data) do
    write(fp, Jason.encode!(data)) #TODO how do we encode atoms? Do they come back out as atoms?? I think my atoms are becoming text during the save...
  end

  @doc ~s(Use this function to open files which have a list of maps, e.g. TidbitDB)
  def read_maplist(fp) when is_bitstring(fp) do
    case File.read(fp) do
      {:ok, ""}   ->
        [] # empty files == empty List
      {:ok, data} ->
        data |> Jason.decode!() |> convert_to_structs()
    end
  end

  def read_maplist(fp, [encrypted?: true, key: key]) when is_bitstring(fp) do
    case File.read(fp) do
      {:ok, ""}   ->
         [] # empty files == empty List
      {:ok, data} ->
         data
         |> Memex.Utils.Encryption.decrypt(key)
         |> Jason.decode!()
         |> convert_to_structs()
    end
  end

  @doc ~s(Writes a list of maps, or even overwrites!, to a file.)
  def write_maplist(fp, data) when is_bitstring(fp) and is_list(data) do
    write(fp, Jason.encode!(data))
  end

  def write_maplist(fp, data, [encrypted?: true, key: key]) when is_bitstring(fp) and is_list(data) do
    encrypted_data =
      data |> Jason.encode!() |> Memex.Utils.Encryption.encrypt(key)

    write(fp, encrypted_data)
  end

  def write(fp, data) when is_bitstring(fp) and is_binary(data) do
    {:ok, file} = File.open(fp, [:write])
    file |> IO.binwrite(data)
    File.close(file) # returns :ok
  end

  # each entry in the maplist ought to have a Struct it can map to
  defp convert_to_structs(list_of_maps) do
    list_of_maps
    |> Enum.map(
         fn(map_with_string_keys) ->
              struct_params =
                map_with_string_keys |> convert_to_keyword_list()
              Kernel.struct!(struct_params[:module] |> String.to_existing_atom(), struct_params)
         end 
         )
    |> Enum.map(
         fn
           %Memex.TidBit{}  = t ->
                # if the TidBit contains a Struct in it's data field, we want to reconstruct it here 
                case t.data do
                  %{"module" => m} ->
                      new_data = Kernel.struct!(m |> String.to_existing_atom(), t.data |> convert_to_keyword_list())
                      t |> Map.merge(%{data: new_data})
                  _else ->
                      t
                end
           %Memex.Password{} = p ->
                p
         end
         )
  end

  defp convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    map |> Keyword.new(fn {k,v} -> {String.to_atom(k),v} end) #TODO figure out how to use `to_existing_atom` here (maybe? Maybe not worth it? just don't blow up the atom table :D)
  end
end
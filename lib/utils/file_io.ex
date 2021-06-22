defmodule Memex.Utils.FileIO do
  
  @moduledoc ~s(Open a file and interpret it as a Map.)
  def readmap(fp) when is_bitstring(fp) do
    case File.read(fp) do
      {:ok, ""}   -> %{} # empty files == empty Map
      {:ok, data} -> data |> Jason.decode!()
    end
  end

  @moduledoc ~s(Writes a map to, and even overwrites!, a file.)
  def writemap(fp, data) when is_map(data) do
    write(fp, Jason.encode!(data))
  end

  @moduledoc ~s(Use this function to open files which have a list of maps, e.g. TidbitDB)
  def read_maplist(fp) when is_bitstring(fp) do
    case File.read(fp) do
      {:ok, ""}   -> [] # empty files == empty List
      {:ok, data} -> data |> Jason.decode!()
    end
  end

  @moduledoc ~s(Writes a list of maps, or even overwrites!, to a file.)
  def write_maplist(fp, data) when is_bitstring(fp) and is_list(data) do
    write(fp, Jason.encode!(data))
  end

  def write(fp, data) when is_bitstring(fp) and is_binary(data) do
    {:ok, file} = File.open(fp, [:write])
    file
    |> IO.binwrite(data)
    |> File.close() # returns :ok
  end
end
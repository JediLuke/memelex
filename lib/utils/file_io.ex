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

  def write(fp, data) when is_bitstring(fp) and is_binary(data) do
    {:ok, file} = File.open(fp, [:write])
    file
    |> IO.binwrite(data)
    |> File.close() # returns :ok
  end
end
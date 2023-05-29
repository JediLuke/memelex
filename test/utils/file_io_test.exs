defmodule Memelex.Utils.FileIOTest do
  use ExUnit.Case
  alias Memelex.Utils.FileIO

  @file_path "test_data.json"

  setup do
    # Clean up the file before and after each test
    on_exit(fn ->
      File.rm(@file_path)
    end)

    :ok
  end

  test "saves and loads a single map" do
    data = %{"key" => "value", "number" => 42}
    assert {:ok, ^data} = FileIO.save(@file_path, data)
    assert {:ok, ^data} = FileIO.load(@file_path)
  end

  test "saves and loads a list of maps" do
    data = [
      %{"id" => 1, "name" => "Alice"},
      %{"id" => 2, "name" => "Bob"}
    ]

    assert {:ok, ^data} = FileIO.save(@file_path, data)
    assert {:ok, ^data} = FileIO.load(@file_path)
  end

  test "returns an error when loading a non-existent file" do
    assert {:error, :enoent} = FileIO.load("non_existent_file.json")
  end

  test "returns an error when loading an invalid JSON file" do
    {:ok, _} = File.write(@file_path, "invalid json")
    assert {:error, _} = FileIO.load(@file_path)
  end
end

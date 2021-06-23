defmodule Memex.My.Passwords do

  def list do
    {:ok, passwords_file} =
            Memex.Env.WikiManager
            |> GenServer.call(:whats_the_file_we_store_passwords_in_again?)
    
    IO.inspect(passwords_file, label: "Passwords file")
    passwords_file |> Memex.Utils.FileIO.read_maplist()
  end
end
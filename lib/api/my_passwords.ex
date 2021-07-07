defmodule Memex.My.Passwords do
  alias Memex.Env.PasswordManager

  def list do
    {:ok, passwords} = GenServer.call(PasswordManager, :list_passwords)
    passwords
  end

  def add(params) do
    new_password = Memex.Password.construct(params)
    GenServer.call(PasswordManager, {:new_password, new_password})
  end

  def find(label) do
    {:ok, password} =
       GenServer.call(PasswordManager, {:find_unredacted_password, label})
    password
  end
end
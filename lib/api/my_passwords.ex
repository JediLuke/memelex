defmodule Memex.My.Passwords do
  alias Memex.Env.PasswordManager

  def new(params) do # API sugar
    create(params)
  end

  def add(params) do # API sugar
    create(params)
  end

  def create(params) do
    new_password = Memex.Password.construct(params)
    GenServer.call(PasswordManager, {:new_password, new_password})
  end

  def find(label) do
    {:ok, password} =
       GenServer.call(PasswordManager, {:find_unredacted_password, label})
    password
  end

  def list do
    {:ok, passwords} = GenServer.call(PasswordManager, :list_passwords)
    passwords
  end

end
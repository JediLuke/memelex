defmodule Memex.My.Passwords do
  alias Memex.Env.PasswordManager

  @simularity_cutoff 0.72 # how close we need labels to be in our search algorithm

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


  def find(%Memex.Password{} = password) do
    case GenServer.call(PasswordManager, {:find_unredacted_password, password}) do
      {:ok, %Memex.Password{} = unredacted_password} ->
          unredacted_password
      {:error, "password not found"} ->
          :not_found
    end
  end

  # search through the labels
  def find(search_term) when is_binary(search_term) do
    password =
      list |> Enum.find(:not_found,
                        & String.jaro_distance(&1.label, search_term) > @simularity_cutoff)

    if password == :not_found do
      :not_found
    else
      find(password)
    end
  end

  def list do
    {:ok, passwords} = GenServer.call(PasswordManager, :list_passwords)
    passwords
  end

  def update(password, updates) do
    GenServer.call(PasswordManager, {:update_password, password, updates})
  end

end
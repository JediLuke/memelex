defmodule Memex.Env.PasswordManager do
  use GenServer
  require Logger
  alias Memex.Utils


  @redacted "***********"

  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end


  def init(env) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, env, {:continue, :open_passwords_file}}
  end


  def handle_continue(:open_passwords_file, state) do

    if not File.exists?(passwords_file(state)) do
      Logger.warn "could not find a Passwords file for this environment. Creating one now..."
      passwords_file(state)
      |> Utils.FileIO.write_maplist([], encrypted?: true, key: secret_key()) # write an empty list to the file
    end

    init_state =
      state
      |> Map.merge(%{passwords: []})
      |> refetch_passwords()

    Logger.info "PasswordManager successfully loaded passwords from disc."
    {:noreply, init_state}
  end

  def handle_call(:list_passwords, _from, state) do
    {:reply, {:ok, state.passwords}, state}
  end

  def handle_call({:new_password, password}, _from, state) do
    write_new_password({state, secret_key()}, password)
    {:reply, :ok, state |> refetch_passwords()} # just re-fetch the list for now...
  end

  def handle_call({:find_unredacted_password, %Memex.Password{} = password}, _from, state) do
    if password = password_exists?(password, state) do
      {:reply, {:ok, find_unredacted(password, state)}, state}
    else
      {:reply, {:error, "password not found"}, state}
    end
  end

  def handle_call({:update_password, password, updates}, _from, state) when is_struct(password) do
    if password = password_exists?(password, state) do
      case overwrite_existing_password({state, secret_key()}, password, updates) do
        :ok    -> {:reply, :ok, state |> refetch_passwords()}
        :error -> {:reply, :error, state}
      end
    else
      {:reply, {:error, "password not found"}, state}
    end
  end







  def handle_call({:delete_password, pword}, _from, state) do
    raise "Can't delete passwords yet"
  end

  
  
  def passwords_file(%{memex_directory: dir}) do
    "#{dir}/passwords.json"
  end

  # returns false if it does not exist, returns the password if it does exist
  def password_exists?(%{uuid: uuid, label: label}, %{passwords: passwords}) do
    passwords |> Enum.find(false, & &1.uuid == uuid and &1.label == label)
  end

  def find_unredacted(%{uuid: uuid, label: label}, state) do
    passwords_file(state)
    |> Utils.FileIO.read_maplist(encrypted?: true, key: secret_key())
    |> Enum.find(& &1.uuid == uuid and &1.label == label)
  end


  def write_new_password({state, key}, %Memex.Password{} = password) do
    #NOTE - it's important here that we go and fetch the data directly from disc
    #       and then overwrite that data - this way, we cant accidentally corrupt the
    #       disc data by using the PasswordManager state (this actually happened...)
    new_passwords_list =
      passwords_file(state)
      |> Utils.FileIO.read_maplist(encrypted?: true, key: secret_key())
      |> Enum.concat([password])

    passwords_file(state)
    |> Utils.FileIO.write_maplist(new_passwords_list,
                                  encrypted?: true, key: secret_key())
  end

  def overwrite_existing_password(_state, password, %{password: @redacted}) do
    raise "we are attempting to overwrite a password with invalid data!! #{inspect password}"
  end

  def overwrite_existing_password({state, key}, %Memex.Password{label: label, uuid: uuid} = password, updates) do
    #NOTE - it's important here that we go and fetch the data directly from disc
    #       and then overwrite that data - this way, we cant accidentally corrupt the
    #       disc data by using the PasswordManager state (this actually happened...)
    new_passwords_list =
      passwords_file(state)
      |> Utils.FileIO.read_maplist(encrypted?: true, key: key)
      |> Enum.reject(& &1.uuid == uuid and &1.label == label)
      |> Enum.concat([password |> Map.merge(updates)]) #TODO this could still be more secure... we could try & use the pipeline in Password struct

    passwords_file(state)
    |> Utils.FileIO.write_maplist(new_passwords_list,
                                  encrypted?: true, key: secret_key())
  end



  defp refetch_passwords(state) do
    %{state|passwords: fetch_redacted_passwords_from_disc(state, secret_key())}
  end

  defp fetch_redacted_passwords_from_disc(state, key) do
    passwords_file(state)
    |> Utils.FileIO.read_maplist(encrypted?: true, key: key)
    |> Enum.map(fn pword -> pword |> Map.replace!(:password, @redacted) end) # dont keep unencrypted passwords in memory...
  end



  defp secret_key do
    "I9AimO3sUrdq4TRqzIeqog==" #TODO - this will be totally different in test environment!!
    #"Luke" |> :base64.encode() #TODO get real key from ENV variable...
  end
end
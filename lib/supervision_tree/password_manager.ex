defmodule Memelex.Env.PasswordManager do
  use GenServer
  require Logger
  alias Memelex.Utils

  @redacted "***********" # this is the string we replace passwords with, so tht we don't keep real passwords in memory unencrypted

  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  def init(env) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, Map.merge(env, %{passwords: %{}}), {:continue, :open_passwords_file}}
  end

  def handle_continue(:open_passwords_file, state) do
    # IO.puts "1111111"
    #TODO if key doesn't exist as a variable, AND there is no passwords file ->
    #       this might be a new memex, or one without password functionality.
    #       We could just log something & go inactive, or even shut-down.
    if key_exists_as_env_variable?() do
      # IO.puts "222222222222"
      passwords = load_init_state_from_passwords_file(state)
      # |> IO.inspect(label: "LLLL")
      {:noreply, %{state|passwords: passwords}}
    else
      Logger.error """
      The mandatory environment variable `MEMEX_PASSWORD_KEY` could not be found.

      Without this environment variable, the Memex is not able to manage
      passwords. To generate a password key, you can create a random string
      with the following Elixir code:

      :crypto.strong_rand_bytes(30) |> Base.encode64()

      Then, save it as an environment variable. In bash, the following
      command will set the environment variable:

      export MEMEX_PASSWORD_KEY=the_randomly_generated_password

      Once this environment variable has been set, you must restart the
      Memex for it to take effect. Until then, functionality which utilizes
      passwords will fail.
      """

      {:stop, :normal, state}
    end
  end

  def handle_call(:list_passwords, _from, state) do
    # IO.puts "INSIDE LIST"
    {:reply, {:ok, state.passwords}, state}
  end

  def handle_call({:new_password, password}, _from, state) do
    write_new_password({state, secret_key()}, password) #TODO we should check that we're not about to overwrite a password with exact same label
    {:reply, {:ok, password}, state |> refetch_passwords_redacted()} # just re-fetch the list for now...
  end

  def handle_call({:find_password, params}, _from, state) do
    if password = password_exists?(params, state) do
      {:reply, {:ok, password}, state}
    else
      {:reply, {:error, "password not found"}, state}
    end
  end

  def handle_call({:find_unredacted_password, %Memelex.Password{} = password}, _from, state) do
    if password = password_exists?(password, state) do
      {:reply, {:ok, find_unredacted(password, state)}, state}
    else
      {:reply, {:error, "password not found"}, state}
    end
  end

  def handle_call({:update_password, password, updates}, _from, state) when is_struct(password) do
    if password = password_exists?(password, state) do
      case overwrite_existing_password({state, secret_key()}, password, updates) do
        :ok    -> {:reply, :ok, state |> refetch_passwords_redacted()}
        :error -> {:reply, :error, state}
      end
    else
      {:reply, {:error, "password not found"}, state}
    end
  end

  def handle_call({:delete_password, password}, _from, state) do
    delete_password({state, secret_key()}, password)
    {:reply, :ok, state |> refetch_passwords_redacted()}
  end
  
  def load_init_state_from_passwords_file(state) do
    if not File.exists?(passwords_file(state)) do
      Logger.warn "Could not find a Passwords file for this environment. Creating one now..."
      passwords_file(state)
      |> Utils.FileIO.write_maplist([], encrypted?: true, key: secret_key()) # write an empty list to the file
    end

    init_state =
      state |> refetch_passwords_redacted()

    Logger.info "PasswordManager successfully loaded passwords from disc."  #TODO this should say how many passwords we got

    init_state
  end

  def key_exists_as_env_variable? do
    case System.get_env("MEMEX_PASSWORD_KEY") do
      nil -> false
      _otherwise -> true
    end
  end

  def passwords_file(%{memex_directory: dir}) do
    "#{dir}/passwords.json"
  end

  # returns false if it does not exist, returns the password if it does exist
  def password_exists?(%{uuid: uuid}, %{passwords: passwords}) do
    passwords |> Enum.find(false, & &1.uuid == uuid)
  end

  #TODO move this to using the {state, key} pattern
  def find_unredacted(%{uuid: uuid, label: label}, state) do
    passwords_file(state)
    |> Utils.FileIO.read_maplist(encrypted?: true, key: secret_key())
    |> Enum.find(& &1.uuid == uuid and &1.label == label)
  end


  def write_new_password({state, key}, %Memelex.Password{} = password) do
    #NOTE - it's important here that we go and fetch the data directly from disc
    #       and then overwrite that data - this way, we cant accidentally corrupt the
    #       disc data by using the PasswordManager state (this actually happened...)
    new_passwords_list =
      passwords_file(state)
      |> Utils.FileIO.read_maplist(encrypted?: true, key: key)
      |> Enum.concat([password])

    passwords_file(state)
    |> Utils.FileIO.write_maplist(new_passwords_list,
                                  encrypted?: true, key: key)
  end

  def overwrite_existing_password(_state, password, %{password: @redacted}) do
    raise "we are attempting to overwrite a password with invalid data!! #{inspect password}"
  end

  def overwrite_existing_password({state, key}, %Memelex.Password{label: label, uuid: uuid} = password, updates) do

    #NOTE - it's important here that we go and fetch the data directly from disc
    #       and then overwrite that data - this way, we cant accidentally corrupt the
    #       disc data by using the PasswordManager state (this actually happened...)
    new_password =
      password
      |> find_unredacted(state)
      |> Map.merge(updates) #TODO this could still be more secure... we could try & use the pipeline in Password struct

    new_passwords_list =
      passwords_file(state)
      |> Utils.FileIO.read_maplist(encrypted?: true, key: key)
      |> Enum.reject(& &1.uuid == uuid and &1.label == label)
      |> Enum.concat([new_password]) 

    passwords_file(state)
    |> Utils.FileIO.write_maplist(new_passwords_list,
                                  encrypted?: true, key: key)
  end

  def delete_password({state, key}, %{uuid: uuid, label: label}) do
    new_passwords_list =
      passwords_file(state)
      |> Utils.FileIO.read_maplist(encrypted?: true, key: key)
      |> Enum.reject(& &1.uuid == uuid and &1.label == label)

    passwords_file(state)
    |> Utils.FileIO.write_maplist(new_passwords_list, encrypted?: true, key: key)
  end

  def reencrypt_with_new_secret_key do
    raise "not possible yet" #TODO
  end

  defp refetch_passwords_redacted(state) do
    fetch_redacted_passwords_from_disc(state, secret_key())
  end

  defp fetch_redacted_passwords_from_disc(state, key) do
    fetch_passwords =
      passwords_file(state)
      |> Utils.FileIO.read_maplist(encrypted?: true, key: key)
      # |> Enum.map(fn pword -> pword |> Map.replace!(:password, @redacted) end) # dont keep unencrypted passwords in memory...

    case fetch_passwords do
      :error ->
        Logger.warn "Fetch passwords failed!"
        []
      passwords when is_list(passwords) ->
        passwords
        |> Enum.map(fn pword -> pword |> Map.replace!(:password, @redacted) end) # dont keep unencrypted passwords in memory...
    end
  end

  def secret_key do
    case System.get_env("MEMEX_PASSWORD_KEY") do
      nil -> raise "need to set `MEMEX_PASSWORD_KEY` as environment variable"
      pass -> pass
    end
  end
end
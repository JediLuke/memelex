defmodule Memex.Env.PasswordManager do
  use GenServer
  require Logger
  alias Memex.Utils


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

    password_list = fetch_passwords_list(state, secret_key())

    Logger.info "PasswordManager successfully loaded passwords from disc."
    {:noreply, state |> Map.merge(%{passwords: password_list})}
  end

  def handle_call(:list_passwords, _from, state) do
    {:reply, {:ok, state.passwords}, state}
  end

  def handle_call({:new_password, %Memex.Password{} = pword}, _from, state) do
    :ok = write_new_password_to_disc(state, pword)
    {:reply, :ok, %{state|passwords: fetch_passwords_list(state, secret_key())}} # just re-fetch the list for now...
  end

  def handle_call({:find_unredacted_password, search_term}, _from, state) do
    similarity_cutoff = 0.72
    same_label? =
      fn p -> String.jaro_distance(search_term, p.label) >= similarity_cutoff end
    password = state.passwords |> Enum.find(:no_password_found, same_label?)
    if password == :no_password_found do
      {:reply, {:error, "could not find any passwords with a label close to: `#{inspect search_term}`"}, state}
    else
      unredacted_password = find_unredacted(password, state)
      {:reply, {:ok, unredacted_password}, state}
    end
  end

  def handle_call({:update_password, password, updates}, _from, state) when is_struct(password) do

    is_this_the_password_were_looking_for? =
      fn(p) -> (p.label == password.label) and (p.uuid == password.uuid) end

    password =
      state.passwords |> Enum.find(:not_found, is_this_the_password_were_looking_for?)

    if password == :not_found do
      {:reply, {:error, "password not found"}, state}
    else

      updated_password = password |> Map.merge(updates) #TODO need more validation on these updates! Could overwrite any field here right now!

      passwords_list_with_old_password_removed =
        state.passwords |> Enum.reject(is_this_the_password_were_looking_for?)
      
      new_passwords_list =
        passwords_list_with_old_password_removed ++ [updated_password]

      passwords_file(state)
      |> Utils.FileIO.write_maplist(new_passwords_list, encrypted?: true, key: secret_key())

      {:reply, :ok, %{state|passwords: new_passwords_list |> redact_raw_passwords()}}
    end
  end

  def handle_call({:delete_password, pword}, _from, state) do
    raise "Can't delete passwords yet"
  end

  defp fetch_passwords_list(state, key) do
    passwords_file(state)
    |> Utils.FileIO.read_maplist(encrypted?: true, key: key)
    |> redact_raw_passwords() # dont keep unencrypted passwords in memory...
  end

  # strip out the raw passwords the list, so only the labels & other data remain
  # we don't want to keep unencrypted passwords in memory...
  defp redact_raw_passwords(passwords_list) do
    passwords_list
    |> Enum.map(fn pword -> pword |> Map.replace!(:password, "***********") end)
  end

  defp find_unredacted(password, state) do
    all_unredacted_passwords = 
      passwords_file(state)
      |> Utils.FileIO.read_maplist(encrypted?: true, key: secret_key())

    all_unredacted_passwords
    |> Enum.find({:error, "could not find password with title `#{password.label}` in the unredacted password list."},
         fn p -> 
           p.label == password.label
         end)
  end

  defp write_new_password_to_disc(state, new_password) do
    all_unredacted_passwords =
      passwords_file(state)
      |> Utils.FileIO.read_maplist(encrypted?: true, key: secret_key())
    
    new_passwords = all_unredacted_passwords ++ [new_password]

    passwords_file(state)
    |> Utils.FileIO.write_maplist(new_passwords, encrypted?: true, key: secret_key())
  end
  
  defp passwords_file(%{memex_directory: dir}) do
    "#{dir}/passwords.json"
  end

  defp secret_key do
    "I9AimO3sUrdq4TRqzIeqog=="
    #"Luke" |> :base64.encode() #TODO get real key from ENV variable...
  end
end
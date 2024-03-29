defmodule Memelex.Utils.ToolBag do
  @moduledoc """
  A general-purpose module for general-purpose functions.
  """

  def generate_uuid(params = %{uuid: _uuid}) do
    params
  end

  def generate_uuid(params) do
    params |> Map.merge(%{uuid: UUID.uuid4()})
  end

  def memex_directory do
    {:ok, dir} = Memelex.WikiServer |> GenServer.call(:whats_the_current_memex_directory?)
    dir
  end

  def text_snippets_directory do
    memex_directory() <> "/text_snippets"
  end

  # TODO we should check if we're within Flamelex here, and if we are (and based on certain configs) we should just *fire off an event* and expect Flamelex to handle it
  def open_external_textfile(filepath) when is_bitstring(filepath) do
    raise "figure this out"
    # if we detect flamelex is running, use that
    # if Code.ensure_compiled?(Flamelex.App) do
    #   # raise "need to open it with Flamelex"
    #   Flamelex.API.Buffer.open(filepath)
    # else
    #   # run this in a separate process so we never lock the IEx console
    #   {:ok, _pid} = Task.Supervisor.start_child(Memelex.Env.TaskSupervisor, fn ->
    #     {"", 0} = System.cmd(open_text_editor_cmd(), [filepath])
    #     :ok
    #   end)
    #   :ok
    # end

    # Memelex.Utils.EventWrapper.event({:open_text_snippet, todays_journal_entry_tidbit})
  end

  # def open_external_textfile(%{type: ["external", "textfile"], data: %{"filepath" => fp}}) do
  #   open_external_textfile(fp)
  # end

  def open_text_editor_cmd do
    case Application.get_env(:memelex, :text_editor_shell_command) do
      nil ->
        raise "No `:text_editor_shell_command` configured."

      c when is_bitstring(c) ->
        c
    end
  end

  def open_vs_code(filepath) do
    # run this in a separate process so we never lock the IEx console
    {:ok, _pid} =
      Task.Supervisor.start_child(Memelex.Env.TaskSupervisor, fn ->
        {"", 0} = System.cmd("code", [filepath])
        :ok
      end)

    :ok
  end
end

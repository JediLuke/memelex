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
    {:ok, dir} =
       Memelex.Env.WikiManager |> GenServer.call(:whats_the_current_memex_directory?)
    dir
  end

  def text_snippets_directory do
    memex_directory() <> "/text_snippets"
  end

  def open_external_textfile(filepath) when is_bitstring(filepath) do
    # run this in a separate process so we never lock the IEx console
    {:ok, _pid} = Task.Supervisor.start_child(Memelex.Env.TaskSupervisor, fn ->
      {"", 0} = System.cmd(open_text_editor_cmd(), [filepath])
      :ok
    end)
    :ok
  end

  def open_external_textfile(%{type: ["external", "textfile"], data: %{"filepath" => fp}}) do
    open_external_textfile(fp)
  end

  def open_text_editor_cmd do
    Application.get_env(:memelex, :text_editor_shell_command)
  end

  def open_vs_code(filepath) do
    # run this in a separate process so we never lock the IEx console
    {:ok, _pid} = Task.Supervisor.start_child(Memelex.Env.TaskSupervisor, fn ->
      {"", 0} = System.cmd("code", [filepath])
      :ok
    end)
    :ok
  end

end
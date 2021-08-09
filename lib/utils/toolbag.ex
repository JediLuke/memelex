defmodule Memex.Utils.ToolBag do
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
       Memex.Env.WikiManager |> GenServer.call(:whats_the_current_memex_directory?)
    dir
  end

  def text_snippets_directory do
    memex_directory() <> "/text_snippets"
  end

  def open_external_textfile(filepath) when is_bitstring(filepath) do
    open_text_editor_cmd = "gedit"
    {:ok, _pid} = Task.Supervisor.start_child(Memex.Env.TaskSupervisor, fn ->
      {"", 0} = System.cmd(open_text_editor_cmd, [filepath])
      :ok
    end)
    :ok
  end

  def open_external_textfile(%{type: ["external", "textfile"], data: %{"filepath" => fp}}) do
    open_external_textfile(fp)
  end

end
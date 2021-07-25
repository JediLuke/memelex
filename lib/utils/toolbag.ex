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


end
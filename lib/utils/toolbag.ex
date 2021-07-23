defmodule Memex.Utils.ToolBag do


  def generate_uuid(params = %{uuid: _uuid}) do
    params
  end
  
  def generate_uuid(params) do
    params |> Map.merge(%{uuid: UUID.uuid4()})
  end

end
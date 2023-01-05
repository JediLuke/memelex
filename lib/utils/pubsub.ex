defmodule Memelex.Utils.PubSub do
  @registrar_proc Memelex.PubSub
  @topic :memelex_state_changes

  # def subscribe, do: subscribe(topic: @topic)

  def subscribe do
    {:ok, _} = Registry.register(@registrar_proc, @topic, [])
    :ok
  end

  def broadcast(msg: msg) do
    Registry.dispatch(@registrar_proc, @topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, msg)
    end)
  end

  # def broadcast(topic: topic, msg: msg) do
  #   Registry.dispatch(@registrar_proc, topic, fn entries ->
  #     for {pid, _} <- entries, do: send(pid, msg)
  #   end)
  # end
end

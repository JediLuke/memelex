defmodule Memex do

  def reload_customizations do
    GenServer.cast(Memex.Env.ExecutiveManager, :reload_the_custom_environment_elixir_modules)
  end
end
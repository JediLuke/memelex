defmodule Memex do
  require Logger

  def reload_customizations do
    GenServer.cast(Memex.Env.ExecutiveManager, :reload_the_custom_environment_elixir_modules)
  end

  def backup do
    Logger.info "triggering immediate backup..."
    send(Memex.Agents.BackupManager, :commence_backup_procedures)
  end

end
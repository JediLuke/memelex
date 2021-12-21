defmodule Memex do
  require Logger

  def reload_customizations do
    GenServer.cast(Memex.Env.ExecutiveManager, :reload_the_custom_environment_elixir_modules)
  end

  # note - collections, and tags, are the same thing! What we need is this https://tiddlywiki.com/#Order%20of%20Tagged%20Tiddlers

  def backup do
    Logger.info "triggering immediate backup..."
    GenServer.cast(Memex.Agents.BackupManager, :commence_backup_procedures)
  end

  def new do
    raise "what we want is to take in a string & create a TidBit"
  end

  def new(params) do
    Memex.My.Wiki.new(params)
  end

  def random do
    # fetch a random TidBit
    Memex.My.Wiki.list() |> Enum.random()
  end

  def recent do
    Memex.My.Wiki.list()
    |> Enum.sort(& &1.created > &2.created)
    |> Enum.take(10)
  end


end
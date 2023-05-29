defmodule Memelex do
  @moduledoc """
  A personal Memex, written in Elixir, inspired by TiddlyWiki.

  Designed to integrate with Flamelex.

  ```
  A memex is a device in which an individual stores all one's books,
  records, and communications, and which is mechanized so that it
  may be consulted with exceeding speed and flexibility. It is
  an enlarged intimate supplement to one's memory.

    —  Dr Vannevar Bush, article: 'As we may think', 1945
  ```
  """

  defdelegate environment_details, to: Memelex.Utils.EnviroTools

  defdelegate initialize_new_environment, to: Memelex.Utils.EnviroTools

  defdelegate load_env(env), to: Memelex.Utils.EnviroTools

  defdelegate deactivate, to: Memelex.Utils.EnviroTools

  defdelegate new(args), to: Memelex.My.Wiki

  defdelegate edit(args), to: Memelex.My.Wiki

  defdelegate find!, to: Memelex.My.Wiki
  defdelegate find!(query), to: Memelex.My.Wiki

  defdelegate search(search_term), to: Memelex.My.Wiki
  defdelegate search(search_term, opts), to: Memelex.My.Wiki

  defdelegate random, to: Memelex.My.Wiki

  defdelegate reload_modz, to: Memelex.Environment

  defdelegate who_am_i, to: Memelex.Utils.EnviroTools

  def backup do
    Memelex.Utils.Backups.perform_backup_procedure()
  end

  def recent(x \\ 10) do
    Memelex.My.Wiki.list()
    |> Enum.sort(&(&1.created > &2.created))
    |> Enum.take(x)
  end
end

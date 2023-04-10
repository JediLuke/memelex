defmodule Memelex do

    #TODO need to specify a buffer?? A TidBit??
    defdelegate edit, to: Memelex.My.Wiki

    defdelegate find!, to: Memelex.My.Wiki
    defdelegate find!(query), to: Memelex.My.Wiki

    # defdelegate search_term(term), to: Memelex.My.Wiki
    defdelegate search(search_term), to: Memelex.My.Wiki
    defdelegate search(search_term, opts), to: Memelex.My.Wiki

    defdelegate reload_modz, to: Memelex.Environment
    # defdelegate search(tag: search_tags), to: Memelex.My.Wiki
    # defdelegate search(tags: search_tags), to: Memelex.My.Wiki
    # defdelegate search(tagged: search_tags), to: Memelex.My.Wiki
end
#   require Logger

#   def reload_customizations do
#     GenServer.cast(Memelex.Env.ExecutiveManager, :reload_the_custom_environment_elixir_modules)
#   end

#   # note - collections, and tags, are the same thing! What we need is this https://tiddlywiki.com/#Order%20of%20Tagged%20Tiddlers

#   def backup do
#     Logger.info "triggering immediate backup..."
#     GenServer.cast(Memelex.Agents.BackupManager, :commence_backup_procedures)
#   end

#   def new do
#     raise "what we want is to take in a string & create a TidBit"
#   end

#   def new(params) do
#     Memelex.My.Wiki.new(params)
#   end

#   def random do
#     # fetch a random TidBit
#     Memelex.My.Wiki.list() |> Enum.random()
#   end

#   def recent do
#     Memelex.My.Wiki.list()
#     |> Enum.sort(& &1.created > &2.created)
#     |> Enum.take(10)
#   end


# end
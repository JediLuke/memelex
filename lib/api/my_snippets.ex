defmodule Memelex.My.Snippets do
  alias Memelex.WikiServer
  alias Memelex.Utils.TidBits.ConstructorLogic, as: TidBitUtils
  @snippets_tag "my_snippets"

  def new(params) do
    params
    |> TidBitUtils.sanitize_conveniences()
    |> Map.merge(%{type: ["external", "textfile"]})
    |> TidBitUtils.apply_tag(@snippets_tag)
    |> Memelex.TidBit.construct()
    |> Memelex.My.Wiki.new()
  end

  def list do
    {:ok, wiki} = GenServer.call(WikiManager, :list_all_tidbits)
    wiki |> Enum.filter(&is_snippet?/1)
  end

  # def open(%{type: ["external", "textfile"], data: %{"filepath" => filepath}}) do
  #   {:ok, _pid} = Memelex.Utils.ToolBag.open_external_textfile(filepath)
  #   :ok
  # end
  
  # def open(%{type: ["text_snippet"], data: %{"filename" => filename}}) do
  #   snippet = Memelex.Utils.ToolBag.text_snippets_directory() <> "/#{filename}"
  #   Memelex.Utils.ToolBag.open_external_textfile(snippet)
  # end


  def list(:text_snippets) do
    list()
    # this is what it is...
    |> Enum.filter(fn tidbit -> tidbit.type |> Enum.member?("text_snippet") end) #OLD WAY
  end


  def is_snippet?(tidbit) do
    external_file?       = tidbit.type |> Enum.member?("external")
    tagged_as_a_snippet? = tidbit.tags |> Enum.member?(@snippets_tag)
    
    external_file? and tagged_as_a_snippet?
  end
end
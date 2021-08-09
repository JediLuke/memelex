defmodule Memex.My.Snippets do
  alias Memex.Env.WikiManager
  alias Memex.Utils.TidBits.ConstructorLogic, as: TidBitUtils
  @snippets_tag "my_snippets"

  def new(params) do
    params
    |> TidBitUtils.sanitize_conveniences()
    |> Map.merge(%{type: ["external", "textfile"]})
    |> TidBitUtils.apply_tag(@snippets_tag)
    |> Memex.TidBit.construct()
    |> Memex.My.Wiki.new_tidbit()
  end

  def list do
    {:ok, wiki} = GenServer.call(WikiManager, :can_i_get_a_list_of_all_tidbits_plz)
    wiki |> Enum.filter(&is_snippet?/1)
  end

  def open(%{type: ["external", "textfile"], data: %{"filepath" => filepath}}) do
    {:ok, _pid} = Memex.Utils.ToolBag.open_external_textfile(filepath)
    :ok
  end
  
  def open(%{type: ["text_snippet"], data: %{"filename" => filename}}) do
    snippet = Memex.Utils.ToolBag.text_snippets_directory() <> "/#{filename}"
    {"", 0} = System.cmd("gedit", [snippet])
    :ok
  end


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
defmodule Memex.TidBit do
  @moduledoc """
  modelled after the `tiddler` of TiddlyWiki.

  https://tiddlywiki.com/#TiddlerFields
  """

  @enforce_keys [:uuid, :title, :created, :creator, :modified, :modifier]

  @derive Jason.Encoder

  defstruct [

      uuid: nil,            # each tiddler has a UUID
      title: nil,           # the unique name for this tidbit
      data: nil,            # the body text of the tidbit

      modified: nil,        # The time this tidbit was last modified
      modifier: nil,        # The name of the last person to modify this TidBit
      created: nil,         # the date this tidbit was created
      creator: nil,         # the name of the person who created ths TidBit

      type: nil,            # the content-type of a tidbit
      tags: [],             # a list of tags ssociated with a TidBit
      links: [],            # a list of all the linked TidBits
      backlinks: [],        # a list of all the Tidbits which link to this one

      history: nil,         # each time a TidBit changes, we track the history #TODO
      
      caption: nil,         # the text to be displayed in a tab or button
      meta: []              # a place to put extra data, e.g. `due_date`
  ]

  @doc ~s(This is here for the sake of the nice API: TidBit.new/1)
  def new(params) do
    Memex.My.Wiki.new(tidbit: params)
  end


  @doc ~s(Creates a valid %TidBit{} - does NOT save it to disc!)
  def construct(params) when is_map(params) do

    validated_params =
      params
      |> generate_uuid()
      |> title_is_valid!()
      |> title_is_unique!()
      |> set_created_and_creator()
      |> set_modified_and_modifier()
      |> validate_type!()
      |> check_the_data_is_valid_for_the_given_type()
      |> validate_tags()

    Kernel.struct!(__MODULE__, validated_params |> convert_to_keyword_list())
  end

  @doc ~s(When we need to reference a TidBit e.g. a list of TidBits, use this function to get the reference.)
  def construct_reference(%{title: t, uuid: uuid}) do
    %{title: t, uuid: uuid}
  end

  def construct_link(%{title: t, uuid: uuid}) do
    "#{t}-[#{t}/#{uuid}]"
  end

  def generate_uuid(params) do
    params |> Map.merge(%{uuid: UUID.uuid4()})
  end

  def title_is_valid!(%{title: t} = params) when is_bitstring(t) do
    params
  end
  def title_is_valid!(_else) do
    raise "invalid or missing title"
  end

  def title_is_unique!(%{title: t} = params) do
    title_already_exists? =
      Memex.My.Wiki.list()
      |> Enum.any?(fn tidbit -> tidbit.title == t end)

    if title_already_exists? do
      raise "title already exists"
    else
      params
    end
  end

  def set_created_and_creator(params) do
    Map.merge(params, %{
      creator: "JediLuke", #TODO get from current environment
      created: DateTime.utc_now()
    })
  end

  def set_modified_and_modifier(params) do
    Map.merge(params, %{
      modified: nil,
      modifier: nil
    })
  end

  def validate_type!(%{type: ["external", "textfile"]} = params) do
    params
  end

  def validate_type!(%{type: :text} = params) do
    params
  end

  def validate_type!(_params) do
    raise "not a valid type" #TODO do this properly lol
  end

  def check_the_data_is_valid_for_the_given_type(%{type: {:external, :textfile}} = params) do
    case params.data do
      {:filepath, fp} when is_bitstring(fp) ->
          if File.exists?(fp) do
               params
          else
               raise "the filepath appears valid, but could not file a file at: #{inspect fp}"
          end
      _else ->
          raise "for external textfiles, data must be in the format: `{:filepath, \"path\"}`"
    end
  end

  def check_the_data_is_valid_for_the_given_type(%{type: :text, data: txt} = params) when is_bitstring(txt) do
    params
  end

  def check_the_data_is_valid_for_the_given_type(%{type: type}) do
    raise "invalid data provided for Tidbit of type: #{inspect type}"
  end

  def validate_tags(%{tags: tags} = params) when is_list(tags) do
    #TODO probably need a list of tags somewhere...
    if Enum.any?(tags, fn(tag) -> not is_bitstring(tag) end) do
      raise "one or more of the tags were not bitstrings"
    else
      params
    end
  end
  def validate_tags(params) do
    params
  end

  def convert_to_keyword_list(map) do
    # https://stackoverflow.com/questions/54616306/convert-a-map-into-a-keyword-list-in-elixir
    map |> Keyword.new(fn {k,v} -> {k,v} end) # keys are already atoms
  end
end
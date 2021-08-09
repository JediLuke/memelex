defmodule Memex.Utils.TidBits.ConstructorLogic do
  require Logger
  alias Memex.Utils.MiscElixir


  @doc ~s(Creates a valid %TidBit{} - does NOT save it to disc!)
  def construct(params) do
    valid_params =
      params
      |> sanitize_conveniences()
      |> sanitize_and_validate()

    Kernel.struct(Memex.TidBit, valid_params |> MiscElixir.convert_map_to_keyword_list())
  end

  @doc ~s(Make a nice interface to construct, so we dont always have to make everything a map, we can just pass in a string as a title)
  def sanitize_conveniences(title) when is_bitstring(title) do
    sanitize_conveniences(%{title: title})
  end

  def sanitize_conveniences(params) when is_map(params) do
    params # sanitization finished
  end

  # this looks interesting but, dunno, used for passing options?
  #def sanitize(title, keyword_list) when is_bitstring(title) and is_list(keyword_list) do
  #  new(%{title: title} |> Map.merge(keyword_list |> Enum.into(%{})))
  #end

  def sanitize_and_validate(params) do
    params
    |> generate_uuid()
    |> title_is_valid!()
    |> set_created_and_creator()
    |> set_modified_and_modifier()
    |> validate_type!()
    |> make_snippets_file_if_required()
    |> enforce_type_field_is_a_list!()
    |> check_the_data_is_valid_for_the_given_type()
    |> validate_tags()
    #|> assert_all_types_are_strings!()
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

  def set_created_and_creator(params) do
    Map.merge(params, %{
      creator: "JediLuke", #TODO get from current environment
      created: DateTime.utc_now() #TODO use unix time here
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

  def validate_type!(%{type: t} = params) when t in [:text, "text"] do 
    params |> Map.merge(%{type: ["text"]})
  end

  def validate_type!(%{type: {:external, :textfile}} = params) do
    params
    |> Map.merge(%{type: ["external", "textfile"]}) # convert the tuple to a list, because JSON doesn't understand tuples
    |> validate_type!()
  end

  # in truth there is no such type as a `:text_snippet`, we just pretend there is for
  # the sake of maintaining a nice API
  def validate_type!(%{type: snippet} = params) when snippet in [:snippet, :text_snippet] do
    params
    |> Map.merge(%{type: ["external", "textfile"]})
    |> apply_tag("my_snippets")
    |> validate_type!()
  end

  def validate_type!(%{type: p} = params) when p in [:person, "person"] do
    params
    |> Map.merge(%{type: ["person"]})
    |> validate_type!()
  end

  def validate_type!(%{type: unknown}) do
    raise "attempting to create a new TidBit with unknown type: #{inspect unknown}"
  end

  def validate_type!(params) do
    params
    |> Map.merge(%{type: ["text"]}) # default to simple text TidBit if type isn't provided
    |> validate_type!()
  end

  def make_snippets_file_if_required(%{type: ["external", "textfile"], title: title, tags: tlist} = params) when is_list(tlist) do
    if tlist |> Enum.member?("my_snippets") do
        params
        |> Map.merge(%{title: "My notes on: " <> title})
        |> create_new_text_snippet_file()
    else
      params
    end
  end

  def make_snippets_file_if_required(params) do
    params # not required
  end

  def create_new_text_snippet_file(%{uuid: uuid, title: title, data: snippet} = params) when is_bitstring(snippet) do
    new_snippet_filepath =
      Memex.Utils.ToolBag.memex_directory()
      |> Path.join("/text_snippets")
      |> Path.join("/#{uuid}.txt")

    if File.exists?(new_snippet_filepath) do
        raise "we're trying to overwrite an existing text-snippet!!"
    else
      Memex.Utils.FileIO.write(new_snippet_filepath, title <> "\n\n" <> snippet)
      Memex.Utils.ToolBag.open_external_textfile(new_snippet_filepath)

      params
      |> Map.merge(%{data: {:filepath, new_snippet_filepath}})
    end
  end

  def create_new_text_snippet_file(params) do
    create_new_text_snippet_file(params |> Map.merge(%{data: ""})) # insert empty text as default data
  end

  def enforce_type_field_is_a_list!(%{type: [t|_rest]} = params) when is_bitstring(t) do
    #TODO go through the whole list
    params
  end

  def enforce_type_field_is_a_list!(%{type: _t}) do
    raise "type field must be a list of strings"
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["text_snippet"], data: %{filename: filename}} = params) do
    filepath = Memex.Utils.ToolBag.memex_directory() <> "/text_snippets/#{filename}"
    if File.exists?(filepath) do
      params |> Map.merge(%{data: %{"filename" => filename}})
    else
      raise "could not find a text snippet file located at: #{inspect filepath}"
    end
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["external", "textfile"]} = params) do # external means, it's a file saved on the disc
    case params.data do
      {:filepath, fp} when is_bitstring(fp) ->
          if File.exists?(fp) do
               params |> Map.merge(%{data: %{"filepath" => fp}})
          else
               raise "the filepath appears valid, but could not file a file at: #{inspect fp}"
          end
      _else ->
          raise "for external textfiles, data must be in the format: `{:filepath, \"path\"}`"
    end
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["person"]} = params) do
    case params.data do
      %Memex.Person{} ->
         params
      _else ->
         raise "when adding a new person to the Wiki, the data field must be a %Person{} struct"
    end
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["text"], data: txt} = params) when is_bitstring(txt) do
    params
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["text"], data: junk_data}) do
    raise "invalid data provided for creating new Tidbit. #{inspect %{type: :text, data: junk_data}}"
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["text"]} = params) do
    params |> Map.merge(%{data: ""})
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

  def add_tag(params, tag) do
    Logger.warn "Did you mean `apply_tag/2`??"
    apply_tag(params, tag)
  end

  def apply_tag(%{tags: tlist} = params, tag) when is_list(tlist) do
    params |> Map.merge(%{tags: tlist ++ [tag]})
  end

  def apply_tag(%{"tags" => tlist} = params, tag) when is_list(tlist) and is_bitstring(tag) do
    raise "how did we get a string key here??"
  end

  def apply_tag(params, tag) do
    params |> Map.merge(%{tags: [tag]})
  end

  def apply_tags(params, taglist) do
    params |> recursively_merge_tags(taglist)
  end

  def merge_meta(%{meta: quasi_meta} = params, new_meta) do
    %{params|meta: Map.merge(quasi_meta, new_meta)}
  end

  def merge_meta(params, new_meta) do
    params |> Map.merge(%{meta: new_meta})
  end

  defp recursively_merge_tags(params, []), do: params # base case

  defp recursively_merge_tags(%{tags: tlist} = params, [tag|rest]) do
    recursively_merge_tags(params |> Map.merge(%{tags: [tag]}), rest)
  end

  defp recursively_merge_tags(params, taglist) do
    recursively_merge_tags(params |> Map.merge(%{tags: []}), taglist)
  end
end
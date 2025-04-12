defmodule Memelex.Utils.TidBits.ConstructorLogic do
  require Logger
  # alias Memelex.Utils.MiscElixir

  @doc ~s(Creates a valid %TidBit{} - does NOT save it to disc!)
  def construct(params) do
    valid_params =
      params
      |> sanitize_conveniences()
      |> sanitize_and_validate()

    valid_params = valid_params |> Map.delete(:__struct__)
    Kernel.struct(Memelex.TidBit, valid_params |> Enum.into([]))
  end

  @doc ~s(Make a nice interface to construct, so we dont always have to make everything a map, we can just pass in a string as a title)
  def sanitize_conveniences(title) when is_bitstring(title) do
    sanitize_conveniences(%{title: title})
  end

  def sanitize_conveniences(params) when is_map(params) do
    # sanitization finished
    params
  end

  # this looks interesting but, dunno, used for passing options?
  # def sanitize(title, keyword_list) when is_bitstring(title) and is_list(keyword_list) do
  #  new(%{title: title} |> Map.merge(keyword_list |> Enum.into(%{})))
  # end

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

    # |> assert_all_types_are_strings!()
  end

  def generate_uuid(params) do
    params |> Map.merge(%{uuid: UUID.uuid4()})
  end

  # def title_is_valid_or_volatile!(%{is_volatile?: true} = params) do
  #   Logger.warning "creating a voltile tidbit..."
  #   params
  # end

  def title_is_valid!(%{title: t} = params) when is_bitstring(t) do
    #TODO should ssert volatile is false
    params
  end

  def title_is_valid!(_else) do
    raise "invalid or missing title"
  end

  def set_created_and_creator(params) do
    Map.merge(params, %{
      # creator: Memelex.who_am_i(), Memelex.Environment.get_env() |> Map.get(:user)
      creator: "JediLuke",
      # TODO use unix time here?
      created: DateTime.utc_now() |> to_string()
    })
  end

  def set_modified_and_modifier(params) do
    Map.merge(params, %{
      modified: nil,
      modifier: nil
    })
  end

  # def validate_type!(%{type: ["external", "textfile"]} = params) do
  #   params
  # end

  # def validate_type!(%{type: ["external", "wavfile"]} = params) do
  #   params
  # end

  # convert these pseudo-types into the only real types we support, which is a list of strings
  def validate_type!(%{type: t} = params) when t in [:text, "text"] do
    params |> Map.merge(%{type: ["text"]})
  end

  # also allow a single-item list
  def validate_type!(%{type: [t]} = params) when t in [:text, "text"] do
    params |> Map.merge(%{type: ["text"]})
  end

  def validate_type!(%{type: {:external, :textfile}} = params) do
    params
    # convert the tuple to a list, because JSON doesn't understand tuples
    |> Map.merge(%{type: ["external", "textfile"]})
    |> validate_type!()
  end

  @valid_external_types ["textfile", "audio/mpeg"]
  def validate_type!(%{type: ["external", external_type]} = params)
      when external_type in @valid_external_types do
    params |> Map.merge(%{type: ["external", external_type]})
  end

  # in truth there is no such type as a `:text_snippet`, we just pretend there is for
  # the sake of maintaining a nice API
  # TODO maybe we do the same with :voice_memo? Or maybe just ditch this idea...
  def validate_type!(%{type: snippet} = params) when snippet in [:snippet, :text_snippet] do
    params
    |> Map.merge(%{type: ["external", "textfile"]})
    |> apply_tag("my_snippets")
    |> validate_type!()
  end

  # def validate_type!(%{type: p} = params) when p in [:person, "person"] do
  #   params
  #   |> Map.merge(%{type: ["person"]})
  #   |> validate_type!()
  # end

  def validate_type!(%{type: {:struct, struct_module}} = params) when is_atom(struct_module) do
    # TODO maybe we should just ditch this whole idea of having a `:struct` type, and just USE IT DIRECTLY? I think I had a reason for doing it though??
    # Also, keep this tuple, we might aswell, and just convert it to the list (which we need for JSON serializing, I think right?>???)
    params |> Map.merge(%{type: ["struct", struct_module]})
  end

  def validate_type!(%{type: ["struct", struct_module]} = params) when is_atom(struct_module) do
    params |> Map.merge(%{type: ["struct", struct_module]})
  end

  def validate_type!(%{type: nil} = params) do
    # raise "attempting to create a new TidBit with unknown type: #{inspect(unknown)}"
    params
  end

  def validate_type!(%{type: unknown}) do
    raise "attempting to create a new TidBit with unknown type: #{inspect(unknown)}"
  end

  def validate_type!(params) do
    params
    |> Map.merge(%{type: nil})
    |> validate_type!()
  end

  def make_snippets_file_if_required(
        %{type: ["external", "textfile"], title: title, tags: tags_list} = params
      )
      when is_list(tags_list) do
    if tags_list |> Enum.member?("my_snippets") do
      params
      |> Map.merge(%{title: "My notes on: " <> title})
      |> create_new_text_snippet_file()
    else
      params
    end
  end

  def make_snippets_file_if_required(params) do
    # not required
    params
  end

  def create_new_text_snippet_file(%{uuid: uuid, title: title, data: snippet} = params)
      when is_bitstring(snippet) do
    new_snippet_filepath =
      Memelex.Utils.ToolBag.memex_directory()
      |> Path.join("/text_snippets")
      |> Path.join("/#{uuid}.txt")

    if File.exists?(new_snippet_filepath) do
      raise "we're trying to overwrite an existing text-snippet!!"
    else
      Memelex.Utils.FileIO.write(new_snippet_filepath, title <> "\n\n" <> snippet)
      Memelex.Utils.ToolBag.open_external_textfile(new_snippet_filepath)

      params
      |> Map.merge(%{data: {:filepath, new_snippet_filepath}})
    end
  end

  def create_new_text_snippet_file(params) do
    # insert empty text as default data
    create_new_text_snippet_file(params |> Map.merge(%{data: ""}))
  end

  def enforce_type_field_is_a_list!(%{type: nil} = params) do
    Map.merge(params, %{type: []})
  end

  def enforce_type_field_is_a_list!(%{type: []} = params) do
    params
  end

  def enforce_type_field_is_a_list!(%{type: [_type | _rest]} = params) do
    params
  end

  # def enforce_type_field_is_a_list!(%{type: _t}) do
  #   raise "type field must be a list of strings"
  # end

  def check_the_data_is_valid_for_the_given_type(%{type: nil, data: d} = params) when is_binary(d) do
    check_the_data_is_valid_for_the_given_type(params |> Map.put(:type, ["text"]))
    # raise "TidBits with no type cannot contain data"
  end

  def check_the_data_is_valid_for_the_given_type(%{type: [], data: d} = params) when is_binary(d) do
    check_the_data_is_valid_for_the_given_type(params |> Map.put(:type, ["text"]))
    # raise "TidBits with no type cannot contain data"
  end

  def check_the_data_is_valid_for_the_given_type(%{type: nil, data: d} = params) when not is_nil(d) do
    raise "TidBits with no type cannot contain data"
  end

  def check_the_data_is_valid_for_the_given_type(%{type: [], data: d} = params) when not is_nil(d) do
    raise "TidBits with no type cannot contain data"
  end

  def check_the_data_is_valid_for_the_given_type(%{type: nil} = params) do
    Map.merge(params, %{type: [], data: []})
    |> merge_meta(%{"is_draft?" => true})
  end

  def check_the_data_is_valid_for_the_given_type(%{type: []} = params) do
    Map.merge(params, %{type: [], data: []})
    |> merge_meta(%{"is_draft?" => true})
  end

  def check_the_data_is_valid_for_the_given_type(
        %{type: ["text_snippet"], data: %{filename: filename}} = params
      ) do
    filepath = Memelex.Utils.ToolBag.memex_directory() <> "/text_snippets/#{filename}"

    if File.exists?(filepath) do
      params |> Map.merge(%{data: %{"filename" => filename}})
    else
      raise "Could not find a text snippet file located at: #{inspect(filepath)}"
    end
  end

  # external means, it's a file saved on the disc
  def check_the_data_is_valid_for_the_given_type(%{type: ["external", sub_type]} = params) do
    case params.data do
      %{"file_path" => fp} when is_binary(fp) ->
        if File.exists?(fp) do
          params
        else
          if sub_type == "audio/mpeg" do
            # hax hax hax lol, need to ignore it if we make a new voice recording
            params
          else
            raise "Could not create new TidBit - the filepath appears valid, but could not file a file at: #{inspect(params.data)}"
          end
        end

      # TODO maybe just get rid of this tuple thing... what's wrong with string-key maps??
      # {:filepath, fp} when is_bitstring(fp) ->
      #   if File.exists?(fp) do
      #     params |> Map.merge(%{data: %{"file_path" => fp}})
      #   else
      #     raise "the filepath appears valid, but could not file a file at: #{inspect(fp)}"
      #   end

      _else ->
        raise "for external files, data must be in the format: `%{\"file_path\" => \"path\"}`"
    end
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["struct", struct_type]} = params)
      when is_atom(struct_type) do
    if is_struct(params.data, struct_type) do
      params
    else
      raise "A Struct-TidBit of type #{inspect(struct_type)} can only have a struct as it's data field."
    end
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["text"], data: txt} = params)
      when is_binary(txt) do
    params
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["text"], data: junk_data}) do
    raise "invalid data provided for creating new Tidbit. #{inspect(%{type: :text, data: junk_data})}"
  end

  def check_the_data_is_valid_for_the_given_type(%{type: ["text"]} = params) do
    params |> Map.merge(%{data: ""})
  end

  def validate_tags(%{tags: tags} = params) when is_list(tags) do
    # TODO probably need a list of tags somewhere...
    if Enum.any?(tags, fn tag -> not is_binary(tag) end) do
      raise "one or more of the tags were not bitstrings"
    else
      params
    end
  end

  def validate_tags(params) do
    params
  end

  def add_tag(params, tag) do
    Logger.warn("Did you mean `apply_tag/2`??")
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

  def apply_tags(params, taglist) when is_list(taglist) do
    params |> recursively_merge_tags(taglist)
  end

  def merge_meta(%{meta: quasi_meta} = params, new_meta) do
    %{params | meta: Map.merge(quasi_meta, new_meta)}
  end

  def merge_meta(params, new_meta) do
    params |> Map.merge(%{meta: new_meta})
  end

  # base case
  defp recursively_merge_tags(params, []), do: params

  defp recursively_merge_tags(%{tags: tlist} = params, [tag | rest]) do
    recursively_merge_tags(params |> Map.merge(%{tags: tlist ++ [tag]}), rest)
  end

  defp recursively_merge_tags(params, taglist) when is_list(taglist) and length(taglist) >= 1 do
    recursively_merge_tags(params |> Map.merge(%{tags: []}), taglist)
  end
end

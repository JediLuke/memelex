defmodule Memelex.TidBit do #TODO Memelex.Lib.Structs.TidBit
  @moduledoc """
  modelled after the `tiddler` of TiddlyWiki.

  https://tiddlywiki.com/#TiddlerFields

  This module is really only supposed to contain the struct
  definition for TidBits. However, on the command-line, it
  it convenient/untuitive sometimes to think of things from
  a TidBit-centric perspective, e.g. `TidBit.new()` to make
  a new TidBit, so there are some functions declared here
  purely as API-sugar.
  """

  @enforce_keys [:uuid, :title, :created, :creator, :modified, :modifier]

  @derive Jason.Encoder

  require Logger

  defstruct [

      uuid:  nil,       # each tiddler has a UUID
      title: nil,       # the unique name for this tidbit
      data:  nil,       # the body of the tidbit

      modified: nil,    # The time this tidbit was last modified
      modifier: nil,    # The name of the last person to modify this TidBit
      created:  nil,    # the date this tidbit was created
      creator:  nil,    # the name of the person who created ths TidBit

      type:      [],    # the type of a tidbit - could be a "text" for normal text tidbit, or point to an external text snippet, or be a Struct...
      tags:      [],    # a list of tags associated with a TidBit
      links:     [],    # a list of all the linked TidBits
      backlinks: [],    # a list of all the Tidbits which link to this one

      status:  nil,     # an internal flag - we can "archive" TidBits this way

      history: nil,     # each time a TidBit changes, we track the history #TODO

      deleted?: false,  # a flag for allowing soft-delete
      deleted_at: nil,  # timestamp for deletion, if it has been soft-deleted

      caption: nil,     # the text to be displayed in a tab or button
      meta:    [],      # a place to put extra data, e.g. `due_date`
  ]

  def construct(params) do
    Memelex.Utils.TidBits.ConstructorLogic.construct(params)
  end

  @doc ~s(This is here for the sake of the nice API: TidBit.new/1)
  def new(params) do
    Memelex.My.Wiki.new(params)
  end

  # @doc ~s(This is here for the sake of the nice API: TidBit.update/2)
  # def update(tidbit, params) do
  #   Memelex.My.Wiki.update(tidbit, params)
  # end

  # def list do
  #   Memelex.My.Wiki.list()
  # end

  # def find(search_term) do
  #   Memelex.My.Wiki.find(search_term)
  # end

  # def find(exact: search_term) do
  #   Memelex.My.Wiki.find(exact: search_term)
  # end

  def open(%{type: ["external"|_rest]} = tidbit) do
    Memelex.Utils.ToolBag.open_external_textfile(tidbit)
  end



  def link(base_node, link_node) do
    Memelex.My.Wiki.link(base_node, link_node)
  end

  # def tag(tidbit, tag) do
  #   add_tag(tidbit, tag)
  # end

  # def add_tag(tidbit, tag) do
  #   Memelex.My.Wiki.add_tag(tidbit, tag)
  # end

  @doc ~s(When we need to reference a TidBit e.g. a list of TidBits, use this function to get the reference.)
  def construct_reference(%{title: t, uuid: uuid}) do
    %{title: t, uuid: uuid}
  end

  @doc ~s(This is the string format used to reference TidBits inside other TidBits.)
  def construct_link_string(%{title: t, uuid: uuid}) do
    "#{t}-[#{t}/#{uuid}]"
  end

  @doc """
  Apply a modification to a %TidBit{} struct & return the updated struct.

  This function does NOT save the TidBit in the Memexex permanent memory!
  It *only* casts from one struct to another based on a known modification.
  """
  # def modify(
  #   %__MODULE__{gui: %{mode: :edit}} = tidbit,
  #   {:backspace, 1 = x, :at_cursor}
  # ) when is_integer(x) and x >= 1 do

  #   # figure out if we're backspacing the title or the body (which is saved as `data` on a TidBit struct)
  #   focus = tidbit.gui.focus
  #   tidbit_field = case focus do
  #     :title -> :title
  #     :body  -> :data #TODO just call it body, this was a bad idea
  #   end

  #   text_2_backspace = Map.get(tidbit, tidbit_field)
  #   cursor_2_move = Map.get(tidbit.gui.cursors, focus)

  #   {new_data, new_cursor} =
  #     QuillEx.Tools.TextEdit.backspace(text_2_backspace, cursor_2_move, x, :at_cursor)

  #   put_in(tidbit.gui.cursors[focus], new_cursor)
  #   |> Map.put(tidbit_field, new_data)
  # end

  # def modify(%__MODULE__{gui: %{mode: _old_mode}} = tidbit, {:gui, :mode, new_gui_mode}) when new_gui_mode in [:edit, :normal] do
  #   put_in(tidbit.gui.mode, new_gui_mode)
  # end

  # def modify(
  #     %__MODULE__{gui: %{mode: :edit}} = tidbit,
  #     {:insert_text, txt, :at_cursor}) when is_bitstring(txt)
  # do

  #   focus = tidbit.gui.focus
  #   tidbit_field = case focus do
  #     :title -> :title
  #     :body  -> :data #TODO just call it body, this was a bad idea
  #   end

  #   current_text = Map.get(tidbit, tidbit_field)
  #   current_crsr = Map.get(tidbit.gui.cursors, focus)

  #   {new_text, new_cursor} =
  #     QuillEx.Tools.TextEdit.insert_text_at_cursor(%{
  #           old_text: current_text,
  #           cursor: current_crsr,
  #           text_2_insert: txt
  #       })

  #   put_in(tidbit.gui.cursors[focus], new_cursor)
  #   |> Map.put(tidbit_field, new_text)
  # end

  # def modify(
  #   %__MODULE__{gui: %{mode: :edit, focus: :title}} = tidbit,
  #   {:move_cursor, _section, {_delta_line, _delta_col} = delta}
  # ) do
  #   new_cursor = QuillEx.Tools.TextEdit.move_cursor(
  #       tidbit.title,
  #       tidbit.gui.cursors.title,
  #       delta
  #     )

  #   put_in(tidbit.gui.cursors.title, new_cursor)
  # end

  # def modify(
  #   %__MODULE__{gui: %{focus: :body}, type: ["external", "textfile"]} = tidbit,
  #   {:move_cursor, _section, _delta}
  # ) do
  #   Logger.warn "unable to apply modification: `:move_cursor` to tidbit of type: #{inspect tidbit.type}"
  #   tidbit
  # end

  # def modify(
  #   %__MODULE__{gui: %{mode: :edit}} = tidbit,
  #   {:move_cursor, section, {_d_line, _d_col} = delta})
  # do

  #   tidbit_field = case section do
  #     :title -> :title
  #     :body  -> :data #TODO just call it body, this was a bad idea
  #   end

  #   current_text = Map.get(tidbit, tidbit_field)
  #   current_crsr = Map.get(tidbit.gui.cursors, section)

  #   new_cursor = QuillEx.Tools.TextEdit.move_cursor(current_text, current_crsr, delta)

  #   put_in(tidbit.gui.cursors[section], new_cursor)
  # end

  # def modify(%__MODULE__{} = tidbit, {:set_gui_mode, new_mode = :edit, focus: new_focus}) do
  #   new_tidbit_gui =
  #     tidbit.gui |> Map.merge(%{
  #       mode: new_mode,
  #       focus: new_focus,
  #       # stash the current saved contents, incase we discard these edits
  #       stash: %{
  #           title: tidbit.title,
  #           body: tidbit.data
  #       }
  #     })

  #   put_in(tidbit.gui, new_tidbit_gui)
  # end


  # def modify(%__MODULE__{gui: %{mode: :edit}} = tidbit, focus: new_focus) when new_focus in [:title, :body] do
  #   put_in(tidbit.gui.focus, new_focus)
  # end

  def modify(tidbit, {:add_tags, new_tag}) when is_bitstring(new_tag) do
    %{tidbit|tags: tidbit.tags ++ [new_tag]}
    |> IO.inspect(label: "NOW WITH TAGS")
  end














#  def modify(tidbit, {:append_to_title, text}) do
#     title_cursor = tidbit.gui.cursors.title
#     put_in(tidbit.gui.cursors.title, move_cursor(title_cursor, {:columns_right, String.length(text)}))
#     |> Map.put(:title, tidbit.title <> text)
#  end

#  def modify(tidbit, {:append_to_body, text}) do
#     body_cursor = tidbit.gui.cursors.body
#     put_in(tidbit.gui.cursors.body, move_cursor(body_cursor, {:columns_right, String.length(text)}))
#     |> Map.put(:data, tidbit.data <> text)
#  end

#  def modify(tidbit, {:append_to_body, text}) do
#     body_cursor = tidbit.gui.cursors.body
#     put_in(tidbit.gui.cursors.body, move_cursor(body_cursor, {:columns_right, String.length(text)}))
#     |> Map.put(:data, tidbit.data <> text)
#  end



#  def modify(tidbit, {:insert_text, t, in: :body, at: {:cursor, c}}) do
#     {new_data, new_cursor} =
#        QuillEx.Tools.TextEdit.insert_text_at_cursor(%{
#           old_text: tidbit.data,
#           cursor: c,
#           text_2_insert: t
#        })

#     put_in(tidbit.gui.cursors.body, new_cursor)
#     |> Map.put(:data, new_data)
#  end












   # def modify(tidbit, [move_cursor: {:body, delta}]) do
   #    current_cursor = tidbit.gui.cursors.body

   #    new_cursor = QuillEx.Tools.TextEdit.move_cursor(tidbit.data, current_cursor, delta)

   #    put_in(tidbit.gui.cursors.body, new_cursor)
   # end

   # def modify(tidbit, modification) do
   #    Logger.error "Unrecognised modification: #{inspect modification}. No TidBit modification occured..."
   #    tidbit
   # end













  def modify(tidbit, modification) do
    Logger.error "Unrecognised modification: #{inspect modification}. No TidBit modification occured..."
    tidbit
  end

end















# defmodule Flamelex.Structs.TidBit do
#   @moduledoc false
#   require Logger

#   defguard is_valid(data) when is_map(data)

#   @derive Jason.Encoder
#   defstruct [
#     uuid: nil,                # a UUIDv4
#     hash: nil,                # the md5 of the tidbit
#     title: nil,               # Title of the TidBit
#     tags: [],                 # any tags we want to apply to this TidBit
#     creation_timestamp: nil,  # when the TidBit was created
#     content: nil,             # actual TidBit content
#     remind_me_datetime: nil,  # when to remind me (for reminder TidBits)
#     due_datetime: nil,        # the due date (for reminders)
#     log: nil                  # a log of edits for this TidBit
#   ]

#   def initialize(data), do: validate(data) |> create_struct()

#   def ack_reminder(reminder = %__MODULE__{tags: old_tags}) when is_list(old_tags) do
#     new_tags =
#       old_tags
#       |> Enum.reject(& &1 == "reminder")
#       |> Enum.concat(["ackd_reminder"])

#     reminder |> Map.replace!(:tags, new_tags)
#   end


#   ## private functions
#   ## -------------------------------------------------------------------


#   defp validate(%{title: t, tags: tags, content: c} = data)
#     when is_binary(t) and is_list(tags) and is_binary(c) do
#       data = data |> Map.merge(%{
#         uuid: UUID.uuid4(),
#         creation_timestamp: DateTime.utc_now()
#       })

#       # take a hash of all other elements in the map
#       hash =
#         :crypto.hash(:md5, data |> Jason.encode!())
#         |> Base.encode16()
#         |> String.downcase()
#       data |> Map.merge(%{hash: hash}) #TODO test this hashing thing
#   end
#   defp validate(_else), do: :invalid_data

#   defp create_struct(:invalid_data), do: raise "Invalid data provided when initializing #{__MODULE__}."
#   defp create_struct(data), do: struct(__MODULE__, data)

# end

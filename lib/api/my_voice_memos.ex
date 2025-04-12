defmodule Memelex.My.VoiceMemos do
  alias Memelex.Utils.AudioRecorderServer
  require Logger

  @tag "my_voice_memos"

  def record do
    record(generate_file_name())
  end

  def record(title) when is_binary(title) do
    case AudioRecorderServer.start_recording(title) do
      {:recording_started, file_path} ->
        Logger.debug("Recording started. Creating Voice Memo TidBit...")

        Memelex.My.Wiki.new(%{
          title: "Voice Memo: #{title}",
          data: %{"file_path" => file_path},
          tags: [@tag],
          # is it mpeg or wav though??
          type: ["external", "audio/mpeg"]
        })

      {:error, reason} ->
        {:error, reason}
    end
  end

  def new(
        %{
          # TODO convert this to a struct maybe??
          data: %{
            # e.g. "7.340438",
            "duration" => _duration,
            # e.g. "231114_2148.mp3",
            "file_name" => _filename,
            # e.g. "/media/luke/IC RECORDER/REC_FILE/FOLDER01/231114_2148.mp3",
            "file_path" => _filepath,
            # e.g. "audio/mpeg",
            "file_type" => "audio/mpeg",
            # e.g. "2023-11-14 15:48:46.000000000 -0600"
            "time_and_date" => _t_and_d
          }
        } = args
      ) do
    args
    |> Map.merge(%{
      title: "Voice memo: #{generate_title(args.data)}",
      # TODO be more specific about type of mp3 maybe? Also be more specific on incoming filetype for pattern matching
      type: ["external", "audio/mpeg"],
      tags: build_tags(args)
    })
    |> Memelex.My.Wiki.new()
  end

  def build_tags(%{tags: t_list}) when is_list(t_list) do
    t_list ++ [@tag]
  end

  def build_tags(_otherwise), do: [@tag]

  # TODO maybe do a better job, mayube transcription can rename this later? Dunno
  def generate_title(%{"file_name" => file_name}) when is_binary(file_name) and file_name != "" do
    file_name
  end

  def all do
    # TODO don't use list_all & filter... do it inside WIkiServer
    {:ok, tidbits} = GenServer.call(Memelex.WikiServer, :list_all)
    Enum.filter(tidbits, &Enum.member?(&1.tags, @tag))
  end

  def stop_recording do
    AudioRecorderServer.stop_recording()
  end

  def generate_file_name do
    # Reminder, `.wav` is appended to the end of the filename by us when we invoke the `arecord` command
    Memelex.My.current_time()
    |> Memelex.Utils.StringifyDateTimes.format(:voice_memo_filename)
    |> Kernel.<>("-voice-memo")
  end

  def transcribe(%Memelex.TidBit{
        type: ["external", "audio/mpeg"],
        data: %{"file_path" => file_path}
      }) do
    {:ok, result} = Memelex.NxServ.Whisper.transcribe(file_path)
  end
end

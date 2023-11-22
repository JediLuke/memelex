defmodule Memelex.Utils.SonyRecorder do
  @moduledoc """
  A module for handling operations related to a Sony Recorder.
  """

  # alias Memelex.Utils.{Downloader, Analyzer, Saver, Documenter}

  # def download_files_from_recorder do
  #   recordings_path = "/media/usb/recordings/folder01"
  #   destination_path = "/path/to/your/drive"

  #   if File.dir?(recordings_path) do
  #     File.ls!(recordings_path)
  #     |> Enum.each(fn file ->
  #       file_path = Path.join(recordings_path, file)
  #       file_info = File.stat!(file_path)
  #       IO.inspect(file_info, label: "File info for #{file}")

  #       destination_file_path = Path.join(destination_path, file)
  #       # File.cp!(file_path, destination_file_path)
  #     end)
  #   else
  #     IO.puts("Recorder not found.")
  #   end
  # end

  @media_dir "/media/luke"
  @device_path "#{@media_dir}/IC RECORDER"
  @device_recordings_path "#{@device_path}/REC_FILE/FOLDER01"

  def device_path, do: @device_path

  def device_docked? do
    File.dir?(device_path())
  end

  @doc """
  Syncs the recordings from the Sony Recorder to this computer's hard drive.
  """
  def sync_to_drive do
    with {:ok, recordings} <- list_recordings() do
      # NOTE: Don't use Enum.map here, because we want to process
      # each recording one at a time, so that it either succeeds/fails
      # and we move on, rather than failing the whole batch.

      IO.puts("Syncing #{Enum.count(recordings)} recordings from Sony Recorder to hard drive...")

      # calc this once & stash it because we don't want to do this for *every* recording as it does a mkdir -p
      d_dir = destination_directory()

      for rec <- recordings do
        process_recording(rec, d_dir)
      end
    end
  end

  # TODO this should maybe just return ok/error rather than blowing up, so that
  # it might fail one file transfer but still continue with the rest
  def process_recording(rec, destination_dir) do
    rec
    |> analyze_recording()
    |> copy_recording_to_destination(destination_dir)
    |> document_recording_ingest()
    |> delete_recording_from_device()
  end

  # def process_files do
  #   with {:ok, base_recfiles} <- list_files_on_recorder(),
  #     {:ok, recfiles} <-

  #   end

  #   # download_files_from_recorder()
  #   # |> analyze_files()
  #   # |> save_files_to_disk()
  #   # |> move_files_to_drive("/path/to/your/drive")

  #   # |> document_file_creation()
  # end

  # def download_files_from_recorder do
  #   with {:ok, recordings} <- list_files_on_recorder() do
  #     for r <- recordings do
  #       analyze_recording(Path.join(@device_recordings_path, r))
  #     end
  #   end
  # end

  def list_recordings do
    if device_docked?() do
      {:ok, File.ls!(@device_recordings_path)}
    else
      {:error, "Device not docked."}
    end

    # if File.dir?(@device_recordings_path) do
    #   File.ls!(@device_recordings_path)
    #   |> Enum.map(fn file ->
    #     file_path = Path.join(@device_recordings_path, file)
    #     file_info = File.stat!(file_path)
    #     {file, file_info}
    #   end)
    # else
    #   IO.puts("Recorder not found.")
    #   []
    # end
  end

  def list_analyzed_recordings do
    fetch_recording_file_paths()
    |> Enum.map(&analyze_recording/1)
  end

  def fetch_recording_file_paths do
    case list_recordings() do
      {:ok, files} ->
        # add recordings_path to make up the full file path
        # Enum.map(files, &Path.join(@device_recordings_path, &1))
        files

      {:error, _} ->
        []
    end
  end

  def analyze_recording(%{"file_name" => file_name}) when is_binary(file_name) do
    analyze_recording(file_name)
  end

  def analyze_recording(file_name) when is_binary(file_name) do
    file_path = Path.join(@device_recordings_path, file_name)

    %{
      "file_name" => file_name,
      "file_path" => file_path,
      "file_type" => get_file_type(file_path),
      "duration" => get_audio_duration(file_path),
      "time_and_date" => get_time_and_date(file_path)
    }
  end

  # def analyze_files(file_list) do
  #   if is_ffprobe_installed?() do
  #     Enum.map(file_list, fn {file, _file_info} ->
  #       do_analyze_file(file)
  #     end)
  #   else
  #     IO.puts("`ffprobe` is not installed.")
  #     []
  #   end
  # end

  # def do_analyze_file(f) do
  #   file_path = Path.join("/path/to/your/drive", file)
  #   file_type = get_file_type(file_path)
  #   audio_details = get_audio_details(file_path)
  #   duration = get_audio_duration(file_path)
  #   time_and_date = get_time_and_date(file_path)
  #   {file, file_type, audio_details, duration, time_and_date}
  # end

  # def is_ffprobe_installed? do
  #   {_, exit_code} = System.cmd("which", ["ffprobe"])
  #   exit_code == 0
  # end

  def get_file_type(file_path) do
    {result, 0} = System.cmd("file", ["--brief", "--mime-type", file_path])
    String.trim(result)
  end

  # def get_audio_details(file_path) do
  #   {result, 0} =
  #     System.cmd("ffprobe", [
  #       "-v",
  #       "error",
  #       "-select_streams",
  #       "a:0",
  #       "-show_entries",
  #       "stream=channels",
  #       "-of",
  #       "default=noprint_wrappers=1:nokey=1",
  #       file_path
  #     ])

  #   case String.trim(result) do
  #     "1" -> "Mono"
  #     "2" -> "Stereo"
  #     _ -> "Unknown"
  #   end
  # end

  def get_audio_duration(file_path) do
    {result, 0} =
      System.cmd("ffprobe", [
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        file_path
      ])

    String.trim(result)
  end

  def get_time_and_date(file_path) do
    {result, 0} = System.cmd("stat", ["-c", "%y", file_path])
    String.trim(result)
  end

  # # def save_files_to_disk do
  # #   # Use the Saver module to save the analyzed files to disk
  # # end

  # def move_files_to_drive(file_list, destination_path) do
  #   Enum.each(file_list, fn {file, _file_info} ->
  #     file_path = Path.join(@device_recordings_path, file)
  #     destination_file_path = Path.join(destination_path, file)
  #     File.cp!(file_path, destination_file_path)
  #     document_file_creation()
  #   end)
  # end

  def copy_recording_to_destination(
        %{"file_name" => filename, "file_path" => device_filepath} = rec,
        destination_dir
      )
      when is_binary(destination_dir) do
    destination_filepath = Path.join(destination_dir, filename)
    :ok = File.cp!(device_filepath, destination_filepath)
    rec
  end

  # this is the name of the directory in our Memex which will will copy the recordings to
  @memex_save_directory "sony_px470_recordings"
  def destination_directory do
    case Memelex.Environment.get_env() do
      nil ->
        raise "No Memex environment detected. Unable to provide a destination directory for #{__MODULE__}"

      %{memex_directory: memex_directory} ->
        full_destination_path = Path.join(memex_directory, @memex_save_directory)
        # check/create the directory in the Memex
        :ok = File.mkdir_p!(full_destination_path)
        full_destination_path
    end
  end

  def document_recording_ingest(rec) do
    t = Memelex.My.VoiceMemos.new(%{data: rec, tags: ["sony_px470"]})
    Map.merge(rec, %{"tidbit_uuid" => t.uuid})
  end

  def delete_recording_from_device(%{"file_path" => recording_file_on_device} = rec)
      when is_binary(recording_file_on_device) do
    :ok = File.rm!(recording_file_on_device)
    rec
  end
end

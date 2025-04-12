defmodule Memelex.Utils.AudioRecorderServer do
  use GenServer
  require Logger

  # API
  @max_recording_duration :timer.minutes(15)

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # def toggle_record do
  #   GenServer.call(__MODULE__, :toggle_record)
  # end

  def start_recording(title) do
    GenServer.call(__MODULE__, {:start_recording, title})
  end

  def stop_recording do
    GenServer.cast(__MODULE__, :stop_recording)
  end

  # Server Callbacks

  @impl true
  def init(_args) do
    Logger.debug("#{__MODULE__} initializing...")

    init_state = %{
      recording?: false,
      task: nil
    }

    {:ok, init_state}
  end

  # @impl true
  # def handle_call(:toggle_record, _from, state) do
  #   if state.recording? do
  #     # Stop recording
  #     stop_recording_task(state.task)
  #     new_state = %{state | recording?: false, task: nil}
  #     {:reply, {:ok, "Recording stopped."}, new_state}
  #   else
  #     # Start recording
  #     task = start_recording_task("voice_memo")
  #     # Schedule a message to stop recording after 15 minutes
  #     Process.send_after(self(), :timeout, @max_recording_duration)

  #     new_state = %{state | recording?: true, task: task}
  #     {:reply, {:ok, "Recording started."}, new_state}
  #   end
  # end

  @impl true
  @voice_memo_directory "/home/luke/memex/SammyDemo/voice_memos"
  def handle_call({:start_recording, title}, _from, state) do
    if state.recording? do
      {:reply, {:error, "Recording is already in progress"}, state}
    else
      if not File.exists?(@voice_memo_directory) do
        File.mkdir_p(@voice_memo_directory)
      end

      # TODO maybe need to handle spaces here better??
      filepath = "#{@voice_memo_directory}/#{title}.wav"
      task = start_recording_task(filepath)
      Process.send_after(self(), :timeout, @max_recording_duration)

      new_state = %{state | recording?: true, task: task}
      {:reply, {:recording_started, filepath}, new_state}
    end
  end

  @impl true
  def handle_cast(:stop_recording, state) do
    if state.recording? do
      stop_recording_task(state.task)
      new_state = %{state | recording?: false, task: nil}
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    if state.recording? do
      Logger.warn("Recording stopped due to 15-minute timeout.")
      stop_recording_task(state.task)
      new_state = %{state | recording?: false, task: nil}
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  # def handle_info(_anything, state) do
  #   # if state.recording? do
  #   #   Logger.warn("Recording stopped due to 15-minute timeout.")
  #   #   stop_recording_task(state.task)
  #   #   new_state = %{state | recording?: false, task: nil}
  #   #   {:noreply, new_state}
  #   # else
  #   {:noreply, state}
  #   # end
  # end

  # Private Helpers

  defp start_recording_task(filepath) do
    # The System.cmd/3 function in Elixir is used to execute external commands.
    # It takes a command (a string) and a list of arguments to pass to that command,
    # and optionally a keyword list of options. Let's break down each part of the line you provided:

    # Command: "arecord"
    #   "arecord" is the command being executed. It's a standard command-line sound recorder for the ALSA soundcard driver found on Linux systems. It's used for capturing sound (in this case, from a microphone).

    # Arguments: ["-D", "plughw:1,0", "-f", "cd", "-t", "wav", file_name]

    # These are the arguments passed to the arecord command:
    #   -D plughw:1,0: The -D option specifies the audio device to use for recording.
    #      plughw:1,0 refers to a specific hardware device. Here, 1,0 means card 1, device 0.
    #      This is typically determined by the configuration of your audio devices.
    #   -f cd: The -f option sets the format of the recording. cd stands for CD quality,
    #      which is typically 44100 Hz sampling rate, 16-bit samples, and stereo (two channels).
    #   -t wav: The -t option specifies the type (format) of the file to be recorded. wav
    #      indicates that the recording will be stored as a WAV file, which is a common uncompressed audio file format.
    #   file_name: This is not a flag but the name of the file where the recorded audio will be saved.
    #      It's the value you provide when calling the function, representing the output filename.

    # In summary, this System.cmd/3 call starts the arecord command to record audio from a
    # specified ALSA hardware device (plughw:1,0), in CD quality format (-f cd), saves the
    # recording as a WAV file (-t wav), and outputs to the specified file_name.

    Task.async(fn ->
      System.cmd("arecord", ["-D", "plughw:1,0", "-f", "cd", "-t", "wav", filepath])
    end)
  end

  defp stop_recording_task(task) do
    Task.shutdown(task, :brutal_kill)
    System.cmd("pkill", ["-f", "arecord"])
  end
end

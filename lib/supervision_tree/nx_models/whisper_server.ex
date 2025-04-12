defmodule Memelex.NxServ.Whisper do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def transcribe(filepath) do
    GenServer.call(__MODULE__, {:run, filepath})
  end

  def init(_args) do
    Logger.debug("#{__MODULE__} initializing...")
    {:ok, %{}, {:continue, :boot_async}}
  end

  @whisper_tiny {:hf, "openai/whisper-tiny"}
  def handle_continue(:boot_async, _init_state) do
    Logger.debug("#{__MODULE__} booting...")

    {:ok, whisper} = Bumblebee.load_model(@whisper_tiny)
    {:ok, featurizer} = Bumblebee.load_featurizer(@whisper_tiny)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(@whisper_tiny)
    {:ok, generation_config} = Bumblebee.load_generation_config(@whisper_tiny)

    serving =
      Bumblebee.Audio.speech_to_text_whisper(whisper, featurizer, tokenizer, generation_config,
        defn_options: [compiler: EXLA]
      )

    state = %{serving: serving}

    {:noreply, state}
  end

  def handle_call({:run, filepath}, _from, state) when is_binary(filepath) do
    result = Nx.Serving.run(state.serving, {:file, filepath})
    {:reply, {:ok, result}, state}
  end

  def text_only_transcription(whisper_result) do
    whisper_result.chunks |> Enum.map_join(& &1.text) |> String.trim()
  end
end

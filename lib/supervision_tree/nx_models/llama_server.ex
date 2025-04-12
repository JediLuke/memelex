defmodule Memelex.LLModelServer.LlamaVision11B do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    Logger.debug("#{__MODULE__} initializing...")
    {:ok, %{}}
  end

  def call(p) do
    GenServer.call(__MODULE__, %{prompt: p})
  end

  def handle_call(%{prompt: prompt}, _from, state) do
    result = Nx.Serving.batched_run(LlamaVision11B, prompt)
    {:reply, {:ok, result}, state}
  end

  @hf_model "meta-llama/Llama-3.2-11B-Vision-Instruct"
  def serving() do
    model = {:hf, @hf_model}

    {:ok, model_info} = Bumblebee.load_model(model, backend: EXLA.Backend)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(model, module: Bumblebee.Text.LlamaTokenizer)
    {:ok, generation_config} = Bumblebee.load_generation_config(model)

    generation_config = Bumblebee.configure(generation_config, max_new_tokens: 250)

    Bumblebee.Text.generation(model_info, tokenizer, generation_config,
      defn_options: [compiler: EXLA]
    )
  end
end

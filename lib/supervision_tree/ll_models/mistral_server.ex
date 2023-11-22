defmodule Memelex.LLModelServer.Mistral do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    Logger.debug("#{__MODULE__} initializing...")
    {:ok, %{}}
  end

  def handle_call(%{prompt: prompt}, _from, state) do
    # result = Nx.Serving.batched_run(Mistral, prompt)
    result = Nx.Serving.batched_run(Mistral, prompt)
    {:reply, {:ok, result}, state}
  end

  def serving() do
    # mistral = {:local, "/home/toranb/lit/out/lora_merged/Mistral-7B-v0.1"}
    mistral = {:hf, "mistralai/Mistral-7B-Instruct-v0.1"}

    {:ok, model_info} = Bumblebee.load_model(mistral, backend: {EXLA.Backend, client: :host})
    # {:ok, model_info} =
    #   Bumblebee.load_model(mistral,
    #     backend: {EXLA.Backend, client: :host},
    #     module: Bumblebee.Text.Mistral,
    #     architecture: :for_causal_language_modeling
    #   )

    {:ok, tokenizer} = Bumblebee.load_tokenizer(mistral, module: Bumblebee.Text.LlamaTokenizer)
    # {:ok, tokenizer} =
    #   Bumblebee.load_tokenizer(mistral,
    #     module: Bumblebee.Text.Mistral,
    #     architecture: :for_causal_language_modeling
    #   )

    {:ok, generation_config} = Bumblebee.load_generation_config(mistral)

    generation_config = Bumblebee.configure(generation_config, max_new_tokens: 250)

    Bumblebee.Text.generation(model_info, tokenizer, generation_config,
      defn_options: [compiler: EXLA]
    )
  end

  # https://toranbillups.com/blog/archive/2023/10/21/fine-tune-mistral-and-serve-with-nx/
end

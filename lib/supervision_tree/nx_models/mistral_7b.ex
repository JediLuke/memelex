defmodule Memelex.NxModels.Mistral7B do
  # alias Memelex.NxModels.Mistral7B
  # use GenServer
  require Logger

  # def start_link(args) do
  #   GenServer.start_link(__MODULE__, args, name: __MODULE__)
  # end

  # def init(_args) do
  #   Logger.debug("#{__MODULE__} initializing...")
  #   {:ok, %{}}
  # end

  # def handle_call(%{prompt: prompt}, _from, state) do
  #   # result = Nx.Serving.batched_run(Mistral, prompt)
  #   result = Nx.Serving.batched_run(MistralNemo, prompt)
  #   {:reply, {:ok, result}, state}
  # end

  def run(prompt) do
    Nx.Serving.batched_run(Mistral7B, prompt)
  end

  def run_openai(prompt) do
    sys_prompt = """
    You are help us create an application called `Flamelex` which is an emacs clone / tiddlywiki inspired integrated memex, written entirely in Elixir.

    You are to channel the alchemical powers of great programmers past to offer unmatched insight into how we can further develop GUI components, architectural components, internal text editor logic - whatever we need to work on next.
    """

    OpenAI.chat_completion(
            # model: "o1-preview",
            model: "gpt-4o",
            messages: [
              %{"role" => "system", "content" => sys_prompt},
              %{"role" => "system", "content" => Memelex.My.Agents.Zosimos.explain_architecture_prompt()},
              %{"role" => "user", "content" => Memelex.My.Agents.Zosimos.build_hypercard_component_prompt()}
            ]
          )
  end


  # {:ok, model_info} =
    #   Bumblebee.load_model(mistral,
    #     backend: {EXLA.Backend, client: :host},
    #     module: Bumblebee.Text.Mistral,
    #     architecture: :for_causal_language_modeling
    #   )

    # {:ok, tokenizer} = Bumblebee.load_tokenizer(mistral, module: Bumblebee.Text.LlamaTokenizer)
        # mistral = {:local, "/home/toranb/lit/out/lora_merged/Mistral-7B-v0.1"}
    # mistral = {:hf, "mistralai/Mistral-7B-Instruct-v0.1"}

  # @model {:local, "/home/luke/workbench/models/Mistral-Nemo-Instruct-2407"}

  # @model {:local, "/home/luke/workbench/models/Mistral-Nemo-Instruct-2407"}
  @model {:local, "/home/luke/workbench/models/Mistral-7B-Instruct-v0.3"}
  def serving() do

    {:ok, model_info} =
      Bumblebee.load_model(@model,
      type: :bf16,
      backend: {EXLA.Backend, client: :cuda}
    )

    {:ok, tokenizer} =
      Bumblebee.load_tokenizer(@model)

    {:ok, generation_config} =
      Bumblebee.load_generation_config(@model)

    generation_config =
      Bumblebee.configure(generation_config, max_new_tokens: 5000)

      # compile: [batch_size: 16, sequence_length: 130],

    Bumblebee.Text.generation(
      model_info,
      tokenizer,
      generation_config,
      # stream: true,
      compile: [batch_size: 1, sequence_length: 150],
      defn_options: [compiler: EXLA]
    )
    # |> Nx.Serving.batch_size(1)
  end

  # https://toranbillups.com/blog/archive/2023/10/21/fine-tune-mistral-and-serve-with-nx/
end

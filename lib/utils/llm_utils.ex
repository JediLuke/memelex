defmodule Memelex.Utils.LLMs do
  @moduledoc """
  This module provides an interface for interacting with LLMs
  (Large Language Models). The idea is that we should be able
  to swap out different "back-ends", like using OpenAI's API
  vs running an LLM locally.
  """

  def chat_completion(:open_ai, %{
        model: "gpt-3.5-turbo",
        messages: [
          %{role: "system", content: initial_prompt},
          %{role: "system", content: instructions},
          %{role: "user", content: request}
        ]
      }) do
    OpenAI.chat_completion(
      model: "gpt-3.5-turbo",
      messages: [
        %{role: "system", content: initial_prompt},
        %{role: "system", content: instructions},
        %{role: "user", content: request}
      ]
    )
  end

  def chat_completion(:local, text) when is_binary(text) do
    {:ok, gpt2} = Bumblebee.load_model({:hf, "gpt2"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "gpt2"})
    {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "gpt2"})

    serving = Bumblebee.Text.generation(gpt2, tokenizer, generation_config)

    Nx.Serving.run(serving, text)
  end
end

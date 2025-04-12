# defmodule Memelex.Utils.LLMs do
#   #   @moduledoc """
#   #   This module provides an interface for interacting with LLMs
#   #   (Large Language Models). The idea is that we should be able
#   #   to swap out different "back-ends", like using OpenAI's API
#   #   vs running an LLM locally.
#   #   """

#   @open_ai_models ["gpt-3.5-turbo", "gpt-4"]

#   def run_analysis(:open_ai, model, messages) do
#     OpenAI.chat_completion(
#       model: "gpt-4",
#       messages: messages
#     )
#   end
# end

#   def chat_completion(:open_ai, :gpt3_5_turbo, %{
#         model: "gpt-3.5-turbo",
#         messages: [
#           %{role: "system", content: initial_prompt},
#           %{role: "system", content: instructions},
#           %{role: "user", content: request}
#         ]
#       }) do
#     OpenAI.chat_completion(
#       model: "gpt-3.5-turbo",
#       messages: [
#         %{role: "system", content: initial_prompt},
#         %{role: "system", content: instructions},
#         %{role: "user", content: request}
#       ]
#     )
#   end

#   # def chat_completion(:open_ai, model, messages) do
#   #   OpenAI.chat_completion(
#   #     model: model,
#   #     messages: messages
#   #   )
#   # end

#   def do_query_open_ai(state, instruction_prompt, user_prompt) do
#     {:ok, %{choices: [%{"message" => %{"content" => llm_response}}]}} =
#       OpenAI.chat_completion(
#         model: "gpt-4",
#         messages: [
#           %{role: "system", content: state["sys_prompt"]},
#           %{role: "system", content: instruction_prompt},
#           %{role: "user", content: user_prompt}
#         ]
#       )

#     {:ok, llm_response}
#   end

#   def chat_completion(:gpt2, text) when is_binary(text) do
#     {:ok, gpt2} = Bumblebee.load_model({:hf, "gpt2"})
#     {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "gpt2"})
#     {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "gpt2"})

#     serving = Bumblebee.Text.generation(gpt2, tokenizer, generation_config)

#     Nx.Serving.run(serving, text)
#   end
# end

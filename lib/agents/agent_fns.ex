defmodule Memelex.Agents.AgentFunctions do
  @moduledoc """
  A library module containing functions common to all agents.
  """


  @doc """
  Take into account the Agent state & compile a Sitution-Report (Sit-Rep).
  """

  # def get_sit_rep(
  #       %Memelex.TidBit{
  #         data: %Agent{
  #           state: %{
  #             "processing_queue" => ["await_user_response" | _rest],
  #             "chat_history" => chat_history
  #           }
  #         }
  #       } = state
  #     ) do
  #   # raise "lol cant do this yet haha"
  #   %{"role" => "assistant", "content" => content} = List.last(chat_history)

  #   sit_rep = """
  #   We're waiting for the user to respond!

  #   Last LLM msg: #{content}
  #   """

  #   {:ok, sit_rep}
  # end



  # def do_put_agent_state(
  #       :inactive = state,
  #       new_state
  #     ) do
  #   # new_agent = %{agent | state: new_state}
  #   state = tidbit()
  #   new_agent = Agent.new(%{"name" => "luke"})

  #   %{state | data: new_agent}
  # end

  # def query_open_ai(state) when is_map(state) or is_struct(state) do
  #   {:ok, %{choices: [%{"message" => %{"content" => llm_response}}]}} =
  #     OpenAI.chat_completion(
  #       model: "gpt-4",
  #       messages:
  #         [
  #           %{role: "system", content: state["sys_prompt"]},
  #           %{role: "system", content: capt_jones_instruction_prompt(state)}
  #         ] ++ state["chat_history"]
  #     )

  #   {:ok, llm_response}
  # end

  # def query_open_ai(state, instruction_prompt, user_prompt) do
  #   {:ok, %{choices: [%{"message" => %{"content" => llm_response}}]}} =
  #     OpenAI.chat_completion(
  #       model: "gpt-4",
  #       messages: [
  #         %{role: "system", content: state["sys_prompt"]},
  #         %{role: "system", content: instruction_prompt},
  #         %{role: "user", content: user_prompt}
  #       ]
  #     )

  #   {:ok, llm_response}
  # end

  # def do_query_open_ai(args) do
  #   query_open_ai(args)
  # end

  # def do_query_open_ai(foo, bar, baz) do
  #   query_open_ai(foo, bar, baz)
  # end



end

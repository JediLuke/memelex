defmodule Memelex.Agents.Chat do
  alias Memelex.Lib.Structs.MemexConcepts.V01.Agent

  def msg(%Memelex.TidBit{data: %Agent{} = agent}, args) do
    p = construct_prompt(agent, args)
    r = query_llm(p)
    m = parse_response(r)

    IO.puts "The msg back was: #{m}"
    {:ok, m}
  end

  def construct_prompt(agent, args) do
    ~s"This is a test prompt"
  end

  def query_llm(prompt) do
    "No result"
  end

  def parse_response(r) do
    "No msg back"
  end
end

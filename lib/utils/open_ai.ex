defmodule Memelex.Utils.OpenAI do
  @moduledoc """
  Tiny wrapper around OpenAI's chat‑completions endpoint with **no external HTTP
  dependency** – it relies only on Erlang/OTP's built‑in `:httpc`.

  ## Quick‑start

      iex> messages = [
      ...>   %{role: "system", content: "You are a helpful assistant"},
      ...>   %{role: "user",   content: "Hello from Elixir!"}
      ...> ]

      # 1.  Export your key (or pass :api_key option)
      $ export OPENAI_API_KEY="sk-..."

      # 2.  Fire up IEx
      $ iex -S mix

      # 3.  Chat!
      iex> messages = [
      ...>   %{role: "system", content: "You are a helpful assistant"},
      ...>   %{role: "user",   content: "Hello from Elixir!"}
      ...> ]
      iex> {:ok, rsp} = Flamelex.OpenAI.chat(messages)
      iex> rsp["choices"] |> hd() |> Map.get("message") |> Map.get("content") |> IO.puts()

  ### Mix dependencies
  Only `:jason` is assumed for JSON encoding/decoding:

      {:jason, "~> 1.4"}

  ### Note on TLS certificates
  On most systems `:httpc` will find the OS CA store automatically.  If you hit
  `:certificate_unknown` errors, add `certifi` to your deps and uncomment the
  `:ssl` option below.
  """

  require Logger

  @endpoint "https://api.openai.com/v1/chat/completions"
  @default_model "gpt-4o-mini"   # change to the model you actually have access to

  @doc """
  Call the chat‑completions endpoint.

  * `messages` – list of `%{role: ..., content: ...}` maps
  * `opts` – `:model`, `:api_key`, or `:http_opts` (passed to `:httpc`)
  """
  def chat(msg) when is_binary(msg) do
    # use the default prompt
    sys_prompt = "You are an alchemist, communicating to me in the year 2025"

    messages = [
      %{role: "system", content: sys_prompt},
      %{role: "user",   content: msg}
    ]

    response = chat(messages)

    content(response)
  end

  def chat(messages, opts \\ []) when is_list(messages) do
    body =
      %{
        model: Keyword.get(opts, :model, @default_model),
        messages: messages
      }
      |> Jason.encode!()
      |> to_charlist()

    headers = [
      {"authorization", "Bearer " <> api_key!(opts)} |> charify_pair(),
      {"content-type", "application/json"} |> charify_pair()
    ]

    # Uncomment the :ssl line if you need to point httpc at certifi's bundle
    http_opts = Keyword.get(opts, :http_opts, [
      # {:ssl, [verify: :verify_peer, cacertfile: :certifi.cacertfile()]}
    ])

    case :httpc.request(:post, {String.to_charlist(@endpoint), headers, 'application/json', body}, http_opts, []) do
      {:ok, {{_version, 200, _reason}, _resp_headers, resp_body}} ->
        {:ok, Jason.decode!(to_string(resp_body))}

      {:ok, {{_version, status, reason}, _resp_headers, resp_body}} ->
        Logger.error("OpenAI error #{status} #{reason}: #{resp_body}")
        {:error, %{status: status, body: to_string(resp_body)}}

      {:error, reason} ->
        Logger.error("HTTP error #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Convenience wrapper that digs the assistant’s textual reply out of a successful
  response map **or** a `{:ok, map}` tuple.

      iex> {:ok, rsp} = Flamelex.OpenAI.chat(msgs)
      iex> Flamelex.OpenAI.content(rsp)
      "Hello! How are you today? 🙂"
  """
  @spec content(map() | {:ok, map()} | {:error, any()}) :: String.t() | nil
  def content({:ok, resp}), do: content(resp)
  def content(%{"choices" => [%{"message" => %{"content" => txt}} | _]}), do: txt
  def content(_), do: nil

  ## Helpers --------------------------------------------------------------
  defp api_key!(opts) do
    Keyword.get(opts, :api_key) ||
      System.get_env("OPENAI_API_KEY") ||
      raise "Set OPENAI_API_KEY environment variable or pass :api_key option"
  end

  defp charify_pair({k, v}), do: {to_charlist(k), to_charlist(v)}
end

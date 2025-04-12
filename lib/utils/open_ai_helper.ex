# defmodule Memelex.Utils.OpenAIHelper do
#   @base_url "https://api.openai.com/v1"

#   def list_models do
#     {:ok, %{data: models}} = OpenAI.models()
#     for model <- models, do: IO.puts(model["id"])
#   end

#   # def query_available_models() do
#   #   url = "#{@base_url}/models"

#   #   headers = [
#   #     {"Authorization", "Bearer YOUR_API_KEY"},
#   #     {"Content-Type", "application/json"}
#   #   ]

#   #   case HTTPoison.get(url, headers) do
#   #     {:ok, %{status_code: 200, body: body}} ->
#   #       {:ok, body}

#   #     {:ok, %{status_code: status_code, body: body}} ->
#   #       {:error, "Request failed with status code #{status_code}: #{body}"}

#   #     {:error, error} ->
#   #       {:error, "Request failed: #{inspect(error)}"}
#   #   end
#   # end

#   # def handle_result({:ok, %{choices: [%{"message" => %{"content" => result}}]}}) do
#   def handle_result({:ok, %{choices: [choice]}}) when is_map(choice) do
#     %{"message" => %{"content" => content}} = choice
#     content
#   end
# end

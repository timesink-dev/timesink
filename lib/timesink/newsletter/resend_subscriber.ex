defmodule Timesink.Newsletter.Resend do
  @moduledoc """
  Minimal client for Resend Audiences (subscribe-only) using the app-wide HTTP client.
  """
  @endpoint "https://api.resend.com"
  @http Application.compile_env!(:timesink, :http_client)

  defp cfg, do: Application.get_env(:timesink, :resend, [])

  @doc """
  Subscribes an email to the configured Resend Audience.

  Returns:
    {:ok, :subscribed} | {:ok, :already_subscribed} | {:error, reason}
  """
  def subscribe(email, attrs \\ %{}) when is_binary(email) do
    api_key = Keyword.fetch!(cfg(), :api_key)
    audience_id = Keyword.fetch!(cfg(), :audience_id)

    url = "#{@endpoint}/audiences/#{audience_id}/contacts"

    headers = [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}
    ]

    body = Jason.encode!(Map.merge(%{"email" => email}, attrs))
    req = Finch.build(:post, url, headers, body)

    case @http.request(req) do
      {:ok, %Finch.Response{status: status, body: _resp_body}} when status in 200..299 ->
        {:ok, :subscribed}

      {:ok, %Finch.Response{status: 409}} ->
        # contact already exists in audience
        {:ok, :already_subscribed}

      {:ok, %Finch.Response{status: status, body: resp_body}} ->
        {:error, {:http_error, status, safe_decode(resp_body)}}

      {:error, reason} ->
        {:error, {:transport_error, reason}}
    end
  end

  defp safe_decode(body) do
    case Jason.decode(body) do
      {:ok, map} -> map
      _ -> body
    end
  end
end

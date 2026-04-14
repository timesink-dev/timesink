defmodule Timesink.Analytics do
  @moduledoc """
  PostHog server-side event capture.

  Reads config from:

      config :timesink, :posthog,
        project_key: "phc_...",   # Project API Key — used by both JS SDK and server capture
        host: "https://eu.i.posthog.com"

  A missing or blank `project_key` is a no-op — safe in all environments.
  All HTTP calls are fire-and-forget (Task.start) so they never block the caller.
  """

  require Logger

  @posthog_path "/i/v0/e/"

  @doc """
  Capture an event for `distinct_id` with optional `properties` map.

  Returns `:ok` immediately; the HTTP call happens in a background task.
  """
  @spec capture(String.t(), any(), map()) :: :ok
  def capture(event, distinct_id, properties \\ %{}) do
    config = Application.get_env(:timesink, :posthog, [])
    project_key = config[:project_key]
    host = config[:host] || "https://eu.i.posthog.com"

    if is_nil(project_key) or project_key == "" do
      :ok
    else
      Task.start(fn ->
        payload =
          Jason.encode!(%{
            api_key: project_key,
            event: event,
            distinct_id: to_string(distinct_id),
            properties: Map.merge(%{"$lib" => "elixir"}, properties),
            timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
          })

        headers = [{"content-type", "application/json"}]
        url = host <> @posthog_path
        req = Finch.build(:post, url, headers, payload)

        case Finch.request(req, Timesink.Finch) do
          {:ok, %Finch.Response{status: status, body: body}} when status in 200..299 ->
            Logger.debug("[PostHog] Captured #{event} (#{status}): #{body}")

          {:ok, %Finch.Response{status: status, body: body}} ->
            Logger.warning("[PostHog] Unexpected status #{status} for event #{event}: #{body}")

          {:error, reason} ->
            Logger.warning("[PostHog] Capture failed for event #{event}: #{inspect(reason)}")
        end
      end)

      :ok
    end
  end
end

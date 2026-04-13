defmodule Timesink.Notifications.Discord do
  @moduledoc """
  Sends notifications to Discord channels via incoming webhooks.

  Each channel is identified by a named key under `:webhooks` in the config.
  Add as many channels as needed — any key with a `nil` URL is silently skipped.

      # config/runtime.exs
      config :timesink, Timesink.Notifications.Discord,
        webhooks: [
          audience_notes: System.get_env("TIMESINK_DISCORD_WEBHOOK_AUDIENCE_NOTES"),
          film_submissions: System.get_env("TIMESINK_DISCORD_WEBHOOK_FILM_SUBMISSIONS")
        ]

  Channels:
  - `waitlist`         — waitlist joins
  - `signups`          — member signup completions
  - `film_submissions` — film submissions
  - `audience_notes`   — audience notes posted during screenings
  """

  require Logger

  # ── Public API ────────────────────────────────────────────────

  @spec notify_waitlist_join(String.t()) :: :ok
  def notify_waitlist_join(email) do
    post(:waitlist, %{content: "📋 **Waitlist join** — #{email}"})
  end

  @spec notify_user_signup(String.t(), String.t()) :: :ok
  def notify_user_signup(username, email) do
    post(:signups, %{content: "🎉 **New member** — @#{username} (#{email})"})
  end

  @spec notify_film_submission(String.t(), String.t()) :: :ok
  def notify_film_submission(title, director_name) do
    post(:film_submissions, %{content: "🎬 **Film submitted** — *#{title}* by #{director_name}"})
  end

  @spec audience_note_posted(map()) :: :ok
  def audience_note_posted(%{
        username: username,
        body: body,
        offset_seconds: offset_seconds,
        film_title: film_title,
        theater_name: theater_name
      }) do
    timestamp = format_offset(offset_seconds)

    content = """
    🎬 **New audience note** — *#{film_title}* (#{theater_name})
    **@#{username}** at `#{timestamp}`
    > #{body}
    """

    post(:audience_notes, %{content: String.trim(content)})
  end

  # ── Private ──────────────────────────────────────────────────

  defp post(channel, payload) do
    case webhook_url(channel) do
      nil ->
        :ok

      url ->
        body = Jason.encode!(payload)
        headers = [{"Content-Type", "application/json"}]
        req = Finch.build(:post, url, headers, body)

        case http_client().request(req) do
          {:ok, %Finch.Response{status: status}} when status in 200..299 ->
            :ok

          {:ok, %Finch.Response{status: status, body: resp_body}} ->
            Logger.warning("[Discord:#{channel}] Webhook returned #{status}: #{resp_body}")
            :ok

          {:error, reason} ->
            Logger.warning("[Discord:#{channel}] Webhook request failed: #{inspect(reason)}")
            :ok
        end
    end
  end

  defp webhook_url(channel) do
    Application.get_env(:timesink, __MODULE__, [])
    |> Keyword.get(:webhooks, [])
    |> Keyword.get(channel)
  end

  defp http_client do
    Application.get_env(:timesink, :http_client, Timesink.HTTP.FinchClient)
  end

  defp format_offset(nil), do: "00:00:00"

  defp format_offset(total_seconds) when is_integer(total_seconds) do
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    seconds = rem(total_seconds, 60)

    [
      String.pad_leading(to_string(hours), 2, "0"),
      String.pad_leading(to_string(minutes), 2, "0"),
      String.pad_leading(to_string(seconds), 2, "0")
    ]
    |> Enum.join(":")
  end
end

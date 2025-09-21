defmodule TimesinkWeb.Account.PersonalFilmSubmissionsLive do
  use TimesinkWeb, :live_view

  import Ecto.Query

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Timesink.PubSub, "film_submissions")
    end

    submissions =
      Timesink.Cinema.FilmSubmission
      |> where([fs], fs.submitted_by_id == ^socket.assigns.current_user.id)
      |> order_by(desc: :inserted_at)
      |> Timesink.Repo.all()

    {:ok, assign(socket, submissions: submissions)}
  end

  def render(assigns) do
    ~H"""
    <section class="max-w-5xl mx-auto px-6 py-10">
      <.back navigate={~p"/me"}></.back>
      <h2 class="text-xl font-semibold text-white my-8 text-left">
        Film submissions ( {length(@submissions)} )
      </h2>

      <%= if @submissions == [] do %>
        <p class="text-background-black text-center">You haven’t submitted any films yet.</p>
      <% else %>
        <div class="overflow-auto">
          <table class="min-w-full table-auto rounded-md overflow-hidden">
            <thead class="bg-neon-blue-lightest">
              <tr>
                <th class="text-left text-backroom-black text-sm font-semibold px-4 py-3">Title</th>
                <th class="text-left text-backroom-black text-sm font-semibold px-4 py-3">
                  Link
                </th>
                <th class="text-left text-backroom-black text-sm font-semibold px-4 py-3">
                  Submitted
                </th>
                <th class="text-left text-backroom-black text-sm font-semibold px-4 py-3">
                  Status
                </th>
                <th class="text-left text-backroom-black text-sm font-semibold px-4 py-3">
                  Last updated
                </th>
                <th class="text-left text-backroom-black text-sm font-semibold px-4 py-3">Notes</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-neon-blue-lightest/10 bg-backroom-black">
              <%= for s <- @submissions do %>
                <tr class="text-mystery-white">
                  <td class="px-4 py-3 font-medium">
                    {s.title || "Untitled Film"}
                  </td>
                  <td class="px-4 py-3 text-sm">
                    <a href={s.video_url} target="_blank" class="text-neon-blue hover:underline">
                      {s.video_url || "No link provided"}
                    </a>
                  </td>
                  <td class="px-4 py-3 text-sm">
                    {format_datetime(s.inserted_at)}
                  </td>
                  <td class="px-4 py-3 flex items-center gap-2 text-sm">
                    {status_icon(s.status_review)}
                    <span>{human_status(s.status_review)}</span>
                  </td>
                  <td class="px-4 py-3 text-sm">
                    {format_datetime(s.status_review_updated_at)}
                  </td>
                  <td class="px-4 py-3 text-sm italic">
                    {s.review_notes || "—"}
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </section>
    """
  end

  def handle_info({"film_submission_updated", submission}, socket) do
    update_submission_if_owned(submission, socket)
  end

  def handle_info({"backpex:film_submission_updated", submission}, socket) do
    update_submission_if_owned(submission, socket)
  end

  defp update_submission_if_owned(submission, socket) do
    if submission.submitted_by_id == socket.assigns.current_user.id do
      updated =
        socket.assigns.submissions
        |> Enum.map(fn s ->
          if s.id == submission.id, do: submission, else: s
        end)

      {:noreply, assign(socket, submissions: updated)}
    else
      {:noreply, socket}
    end
  end

  defp format_datetime(dt) do
    Timex.format!(dt, "{Mshort} {D}, {YYYY}, {h12}:{m} {AM}")
  end

  defp human_status(:received), do: "Received"
  defp human_status(:under_review), do: "Under Review"
  defp human_status(:accepted), do: "Accepted"
  defp human_status(:rejected), do: "Rejected"

  defp status_icon(:received), do: "📨"
  defp status_icon(:under_review), do: "🔍"
  defp status_icon(:accepted), do: "✅"
  defp status_icon(:rejected), do: "❌"
  defp status_icon(_), do: "🕘"
end

defmodule TimesinkWeb.Accounts.FilmSubmissionsLive do
  use TimesinkWeb, :live_view

  import Ecto.Query

  def mount(_params, _session, socket) do
    submissions =
      Timesink.Cinema.FilmSubmission
      |> where([fs], fs.submitted_by_id == ^socket.assigns.current_user.id)
      |> order_by(desc: :inserted_at)
      |> Timesink.Repo.all()

    assign(socket, submissions: submissions)

    {:ok, assign(socket, submissions: submissions)}
  end

  def render(assigns) do
    ~H"""
    <section class="max-w-5xl mx-auto px-6 py-10">
      <.back navigate={~p"/me"}></.back>
      <h2 class="text-3xl font-bold text-white mb-8 text-center">🎞️ Your Film Submissions</h2>

      <%= if @submissions == [] do %>
        <p class="text-gray-400 text-center">You haven’t submitted any films yet.</p>
      <% else %>
        <div class="overflow-auto">
          <table class="min-w-full table-auto border border-gray-800 rounded-lg overflow-hidden">
            <thead class="bg-gray-900 border-b border-gray-800">
              <tr>
                <th class="text-left text-gray-400 text-sm font-semibold px-4 py-3">Title</th>
                <th class="text-left text-gray-400 text-sm font-semibold px-4 py-3">Submitted</th>
                <th class="text-left text-gray-400 text-sm font-semibold px-4 py-3">Status</th>
                <th class="text-left text-gray-400 text-sm font-semibold px-4 py-3">
                  Last status update
                </th>
                <th class="text-left text-gray-400 text-sm font-semibold px-4 py-3">Notes</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-800 bg-gray-950">
              <%= for s <- @submissions do %>
                <tr class="hover:bg-gray-900 transition">
                  <td class="px-4 py-3 text-white font-medium">
                    {s.title || "Untitled Film"}
                  </td>
                  <td class="px-4 py-3 text-gray-400 text-sm">
                    {format_datetime(s.inserted_at)}
                  </td>
                  <td class="px-4 py-3 flex items-center gap-2 text-sm">
                    {status_icon(s.status_review)}
                    <span class="text-gray-300">{human_status(s.status_review)}</span>
                  </td>
                  <td class="px-4 py-3 text-gray-400 text-sm">
                    {format_datetime(s.status_review_updated_at)}
                  </td>
                  <td class="px-4 py-3 text-amber-200 text-sm italic">
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

  defp format_datetime(dt) do
    Timex.format!(dt, "{Mshort} {D}, {YYYY} — {h12}:{m} {AM}")
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

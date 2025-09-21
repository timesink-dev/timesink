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
      <div class="flex items-center justify-between my-6">
        <h2 class="text-xl font-semibold text-white">Film submissions</h2>
        <span class="inline-flex items-center rounded-full text-xs font-medium px-2.5 py-1
                     bg-zinc-900 text-zinc-300 ring-1 ring-zinc-800">
          {length(@submissions)} total
        </span>
      </div>

      <%= if @submissions == [] do %>
        <!-- Empty state -->
        <div class="w-full rounded-2xl border border-zinc-800 bg-backroom-black/60 p-10 text-center">
          <div class="mx-auto mb-3 h-9 w-9 rounded-full bg-zinc-900 ring-1 ring-zinc-800
                      flex items-center justify-center text-zinc-300">
            🎬
          </div>
          <p class="text-zinc-300 font-medium">No submissions yet</p>
          <p class="text-zinc-500 mt-1">Share your film with the community when you’re ready.</p>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="w-full text-sm border border-zinc-800 rounded-xl overflow-hidden">
            <thead class="bg-zinc-950/70 backdrop-blur border-b border-zinc-800">
              <tr>
                <th class="px-4 py-3 text-left font-medium text-zinc-300">Title</th>
                <th class="px-4 py-3 text-left font-medium text-zinc-300">Link</th>
                <th class="px-4 py-3 text-left font-medium text-zinc-300">Submitted</th>
                <th class="px-4 py-3 text-left font-medium text-zinc-300">Status</th>
                <th class="px-4 py-3 text-left font-medium text-zinc-300">Last updated</th>
                <th class="px-4 py-3 text-left font-medium text-zinc-300">Notes</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-800 bg-backroom-black/60">
              <%= for s <- @submissions do %>
                <tr class="text-zinc-200 hover:bg-zinc-900/40 transition-colors">
                  <td class="px-4 py-3 font-medium">
                    {s.title || "Untitled Film"}
                  </td>

                  <td class="px-4 py-3">
                    <div class="max-w-[320px] truncate">
                      <a
                        href={s.video_url}
                        target="_blank"
                        class="inline-flex items-center gap-1.5 text-zinc-200 hover:text-white underline underline-offset-4"
                      >
                        <span class="truncate">{s.video_url || "No link provided"}</span>
                        <.icon name="hero-arrow-up-right-mini" class="h-4 w-4" />
                      </a>
                    </div>
                  </td>

                  <td class="px-4 py-3 text-zinc-400">
                    {format_datetime(s.inserted_at)}
                  </td>

                  <td class="px-4 py-3">
                    <span class={"inline-flex items-center gap-2 px-2.5 py-1 rounded-full text-xs font-medium ring-1 " <>
                                  status_ring_classes(s.status_review) <>
                                  " " <> status_bg_text_classes(s.status_review)}>
                      <span class={"h-1.5 w-1.5 rounded-full " <> status_dot_classes(s.status_review)}>
                      </span>
                      {human_status(s.status_review)}
                    </span>
                  </td>

                  <td class="px-4 py-3 text-zinc-400">
                    {safe_datetime(s.status_review_updated_at)}
                  </td>

                  <td class="px-4 py-3">
                    <span class="text-zinc-400 italic line-clamp-2">{s.review_notes || "—"}</span>
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

  # Safer date for nils
  defp safe_datetime(nil), do: "—"
  defp safe_datetime(dt), do: format_datetime(dt)

  # Status → human text (yours, kept)
  defp human_status(:received), do: "Received"
  defp human_status(:under_review), do: "Under Review"
  defp human_status(:accepted), do: "Accepted"
  defp human_status(:rejected), do: "Rejected"
  defp human_status(_), do: "Pending"

  # Status → color classes (Resend-like: calm pills with subtle rings)
  defp status_bg_text_classes(:received), do: "bg-zinc-900 text-zinc-300"
  defp status_bg_text_classes(:under_review), do: "bg-amber-900/20 text-amber-300"
  defp status_bg_text_classes(:accepted), do: "bg-emerald-900/20 text-emerald-300"
  defp status_bg_text_classes(:rejected), do: "bg-rose-900/20 text-rose-300"
  defp status_bg_text_classes(_), do: "bg-zinc-900 text-zinc-300"

  defp status_ring_classes(:received), do: "ring-zinc-800"
  defp status_ring_classes(:under_review), do: "ring-amber-800/60"
  defp status_ring_classes(:accepted), do: "ring-emerald-800/60"
  defp status_ring_classes(:rejected), do: "ring-rose-800/60"
  defp status_ring_classes(_), do: "ring-zinc-800"

  defp status_dot_classes(:received), do: "bg-zinc-500"
  defp status_dot_classes(:under_review), do: "bg-amber-400"
  defp status_dot_classes(:accepted), do: "bg-emerald-400"
  defp status_dot_classes(:rejected), do: "bg-rose-400"
  defp status_dot_classes(_), do: "bg-zinc-500"
end

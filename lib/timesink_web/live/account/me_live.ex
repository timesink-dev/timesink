defmodule TimesinkWeb.Account.MeLive do
  use TimesinkWeb, :live_view
  import Ecto.Query, only: [from: 2]

  alias Timesink.Repo
  alias Timesink.Token
  alias Timesink.UserGeneratedInvite
  import TimesinkWeb.Account.MePageItem

  @max_invites 2
  @base_url Application.compile_env(:timesink, :base_url)
  @copy_reset_ms 2000

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    invites = list_invites(user.id)

    {:ok,
     assign(socket,
       current_user: socket.assigns.current_user,
       invites: invites,
       invites_left: max(@max_invites - length(invites), 0),
       copied_url: nil,
       max_invites: @max_invites
     )}
  end

  def render(assigns) do
    ~H"""
    <section id="user-overview" phx-hook="CopyBus" class="mt-16">
      <div class="max-w-2xl mx-auto">
        <.me_page_item
          title="Account"
          items={[
            %{
              title: "Profile",
              icon: "hero-identification",
              link: ~p"/me/profile"
            },
            %{
              title: "Security",
              icon: "hero-lock-closed",
              link: ~p"/me/security"
            }
          ]}
        />
        <.me_page_item
          title="Activity"
          items={[
            %{
              title: "Notifications",
              icon: "hero-bolt",
              coming_soon: true
            },
            %{
              title: "Film submissions",
              icon: "hero-film",
              link: ~p"/me/film-submissions"
            }
          ]}
        />
        <.me_page_item
          title="Integrations"
          items={[
            %{
              title: "Tips",
              icon: "hero-currency-dollar",
              coming_soon: true
            }
          ]}
        />
        <!-- Invites UI -->
        <%!-- <div class="mt-8 rounded-2xl border border-zinc-800 bg-dark-theater-primary/60 p-5 md:p-6">
          <div class="flex items-center justify-between gap-x-8 md:gap-x-2">
            <div>
              <h3 class="flex items-center gap-2 text-lg md:text-lg text-mystery-white pb-1">
                <span> Invites </span>
                <.icon name="hero-ticket-solid" class="h-5 w-5 text-neon-red-light" />
              </h3>

              <p class="text-sm text-zinc-400">
                Share a one-time ticket entry link so friends can join immediately
              </p>
            </div>

            <button
              type="button"
              phx-click="generate_invite"
              disabled={@invites_left == 0}
              class={[
                "inline-flex items-center gap-2 rounded-xl px-3 py-2 font-medium transition",
                if(@invites_left == 0,
                  do: "bg-zinc-700/60 text-zinc-400 cursor-not-allowed",
                  else: "bg-dark-theater-primary text-mystery-white hover:opacity-90"
                )
              ]}
            >
              <!-- plus icon -->
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4"
                viewBox="0 0 24 24"
                fill="currentColor"
                aria-hidden="true"
              >
                <path d="M11 4a1 1 0 1 1 2 0v7h7a1 1 0 1 1 0 2h-7v7a1 1 0 1 1-2 0v-7H4a1 1 0 1 1 0-2h7V4z" />
              </svg>
              <span>Generate</span>
            </button>
          </div>

          <div class="mt-3 text-xs text-zinc-500">
            {if @invites_left > 0,
              do: "#{@invites_left} of #{@max_invites} invites left",
              else: "All #{@max_invites} invites generated"} · No expiration
          </div>

          <ul class="mt-5 space-y-3">
            <li
              :for={inv <- @invites}
              class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 rounded-xl border border-zinc-800 bg-backroom-black/40 px-3 py-3"
            >
              <div class="min-w-0">
                <div class="flex items-center gap-2">
                  <span class={[
                    "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                    inv.status == "valid" &&
                      "bg-emerald-600/20 text-emerald-300 ring-1 ring-emerald-600/40",
                    inv.status == "invalid" &&
                      "bg-amber-600/20 text-amber-300 ring-1 ring-amber-600/40",
                    inv.status not in ["valid", "invalid"] &&
                      "bg-zinc-700/40 text-zinc-300 ring-1 ring-zinc-600/50"
                  ]}>
                    <%= case inv.status do %>
                      <% "valid" -> %>
                        Valid
                      <% "invalid" -> %>
                        Used
                      <% other -> %>
                        {String.capitalize(to_string(other))}
                    <% end %>
                  </span>
                </div>
                <div class="mt-1 truncate text-sm text-zinc-300">{inv.url}</div>
              </div>

              <div class="flex items-center gap-2">
                <button
                  type="button"
                  phx-click="copy_invite"
                  phx-value-url={inv.url}
                  class="inline-flex items-center gap-2 rounded-lg bg-zinc-800/70 hover:bg-zinc-700 px-3 py-2 text-sm text-zinc-200 transition"
                  aria-label={(@copied_url == inv.url && "Copied") || "Copy to clipboard"}
                >
                  <!-- icon swaps: clipboard -> green check -->
                  <%= if @copied_url == inv.url do %>
                    <!-- check icon -->
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4 text-emerald-400"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path d="M9 16.2l-3.5-3.5a1 1 0 10-1.4 1.4l4.2 4.2a1 1 0 001.4 0l9-9a1 1 0 10-1.4-1.4L9 16.2z" />
                    </svg>
                  <% else %>
                    <!-- clipboard icon -->
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path d="M8 7a2 2 0 012-2h8a2 2 0 012 2v9a2 2 0 01-2 2h-8a2 2 0 01-2-2V7zm-3 3h1v7a4 4 0 004 4h7v1a2 2 0 01-2 2H7a4 4 0 01-4-4V12a2 2 0 012-2z" />
                    </svg>
                  <% end %>
                </button>
              </div>
            </li>
          </ul>
        </div> --%>
      </div>
    </section>
    """
  end

  def handle_event("generate_invite", _params, socket) do
    case UserGeneratedInvite.generate_invite(socket.assigns.current_user.id) do
      {:ok, _url} ->
        invites = list_invites(socket.assigns.current_user.id)

        {:noreply,
         assign(socket, invites: invites, invites_left: max(@max_invites - length(invites), 0))}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  def handle_event("copy_invite", %{"url" => url}, socket) do
    # trigger client clipboard write; then show checkmark for a bit
    Process.send_after(self(), {:clear_copied, url}, @copy_reset_ms)

    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: url})
     |> assign(copied_url: url)}
  end

  def handle_info({:clear_copied, url}, %{assigns: %{copied_url: url}} = socket) do
    {:noreply, assign(socket, copied_url: nil)}
  end

  def handle_info({:clear_copied, _url}, socket) do
    # Stale timer fired after user clicked another link; ignore.
    {:noreply, socket}
  end

  defp list_invites(user_id) do
    from(t in Token,
      where: t.user_id == ^user_id and t.kind == :invite,
      order_by: [desc: t.inserted_at]
    )
    |> Repo.all()
    |> Enum.map(fn t ->
      %{
        id: t.id,
        url: "#{@base_url}/invite/#{t.secret || t.token}",
        status: (t.status || :valid) |> to_string()
      }
    end)
  end
end

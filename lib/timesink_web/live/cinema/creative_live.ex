defmodule TimesinkWeb.Cinema.CreativeLive do
  use TimesinkWeb, :live_view

  import Ecto.Query
  alias Timesink.{Repo}
  alias Timesink.Cinema.{Creative, FilmCreative, CreativeClaims}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    creative =
      Creative
      |> Repo.get(id)
      |> case do
        nil -> nil
        c -> Repo.preload(c, :user)
      end

    case creative do
      nil ->
        {:ok, assign(socket, not_found: true)}

      %Creative{} ->
        films = load_films(id)
        already_claimed? = already_claimed?(socket.assigns[:current_user])

        {:ok,
         socket
         |> assign(
           creative: creative,
           films: films,
           already_claimed?: already_claimed?,
           claim_open?: false,
           claim_message: "",
           claim_status: nil
         )}
    end
  end

  @impl true
  def render(%{not_found: true} = assigns) do
    ~H"""
    <section class="px-4 md:px-6 py-16">
      <div class="max-w-3xl mx-auto text-center">
        <h1 class="text-xl md:text-2xl font-semibold text-mystery-white">Creative not found</h1>
        <p class="mt-3 text-zinc-400">We couldn't find that creative profile.</p>
        <.link navigate={~p"/"} class="inline-block mt-6 text-neon-blue-lightest hover:opacity-80">
          Back to home
        </.link>
      </div>
    </section>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="px-4 md:px-6 pb-16">
      <div class="mx-auto max-w-3xl mt-16">
        <!-- Header -->
        <div class="rounded-2xl bg-backroom-black/60 backdrop-blur ring-1 ring-zinc-800 px-6 py-8">
          <div class="flex items-start justify-between gap-4">
            <div>
              <h1 class="text-2xl font-semibold text-mystery-white">
                {Creative.full_name(@creative)}
              </h1>
              <%= if @creative.user do %>
                <.link
                  navigate={"/@#{@creative.user.username}"}
                  class="mt-1 inline-flex items-center gap-1.5 text-sm text-neon-blue-lightest hover:opacity-80"
                >
                  <.icon name="hero-user-circle" class="h-4 w-4" /> @{@creative.user.username}
                </.link>
              <% end %>
            </div>

            <%= if @creative.user do %>
              <span class="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/15 border border-emerald-500/30 px-3 py-1 text-xs font-medium text-emerald-400">
                <.icon name="hero-film" class="h-3.5 w-3.5" /> TimeSink Creative
              </span>
            <% end %>
          </div>
          
    <!-- Claim CTA -->
          <%= if is_nil(@creative.user_id) && @current_user && !@already_claimed? && @claim_status != :submitted do %>
            <div class="mt-6 border-t border-zinc-800 pt-5">
              <%= if !@claim_open? do %>
                <p class="text-sm text-zinc-400 mb-3">Are you this creative?</p>
                <.button phx-click="open_claim" color="primary" class="text-sm">
                  Claim this profile
                </.button>
              <% else %>
                <p class="text-sm text-zinc-300 mb-3 font-medium">
                  Submit a claim for
                  <span class="text-mystery-white">{Creative.full_name(@creative)}</span>
                </p>
                <p class="text-xs text-zinc-500 mb-4">
                  Tell us briefly why this is you — a film you directed, your role, or any context that helps us verify.
                </p>
                <form phx-submit="submit_claim" class="space-y-3">
                  <textarea
                    name="message"
                    rows="3"
                    placeholder="e.g. I directed Bitter Rivals (2019), listed above."
                    class="w-full bg-zinc-900 border border-zinc-700 rounded-lg px-4 py-2.5 text-sm text-mystery-white placeholder:text-zinc-600 focus:outline-none focus:ring-1 focus:ring-neon-blue-lightest resize-none"
                  >{@claim_message}</textarea>
                  <div class="flex gap-3">
                    <.button type="submit" color="primary" class="text-sm">
                      Submit claim
                    </.button>
                    <.button phx-click="close_claim" type="button" color="secondary" class="text-sm">
                      Cancel
                    </.button>
                  </div>
                </form>
              <% end %>
            </div>
          <% end %>

          <%= if @claim_status == :submitted do %>
            <div class="mt-6 border-t border-zinc-800 pt-5">
              <p class="text-sm text-emerald-400">
                Your claim has been submitted. We'll review it and get back to you by email.
              </p>
            </div>
          <% end %>
        </div>
        
    <!-- Filmography -->
        <div class="mt-5 rounded-2xl bg-backroom-black/60 backdrop-blur ring-1 ring-zinc-800">
          <div class="px-6 py-3 border-b border-zinc-800">
            <h2 class="text-base font-medium text-mystery-white">Filmography</h2>
          </div>
          <div class="divide-y divide-zinc-800/60">
            <%= if @films == [] do %>
              <p class="px-6 py-5 text-sm text-zinc-500">No films listed yet.</p>
            <% else %>
              <%= for {film, role, subrole} <- @films do %>
                <div class="px-6 py-4 flex items-center justify-between gap-4">
                  <div>
                    <p class="text-sm font-medium text-mystery-white">{film.title}</p>
                    <p class="text-xs text-zinc-500 mt-0.5">
                      {film.year}
                      <%= if subrole do %>
                        · <span class="capitalize">{role}</span> ({subrole})
                      <% else %>
                        · <span class="capitalize">{role}</span>
                      <% end %>
                    </p>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </section>
    """
  end

  @impl true
  def handle_event("open_claim", _params, socket) do
    {:noreply, assign(socket, claim_open?: true)}
  end

  @impl true
  def handle_event("close_claim", _params, socket) do
    {:noreply, assign(socket, claim_open?: false, claim_message: "")}
  end

  @impl true
  def handle_event("submit_claim", %{"message" => message}, socket) do
    %{current_user: user, creative: creative} = socket.assigns

    case CreativeClaims.submit_claim(user, creative.id, message) do
      {:ok, _claim} ->
        {:noreply, assign(socket, claim_status: :submitted, claim_open?: false)}

      {:error, _changeset} ->
        {:noreply,
         put_flash(socket, :error, "Could not submit claim. You may have already submitted one.")}
    end
  end

  # --- helpers ---

  defp load_films(creative_id) do
    from(fc in FilmCreative,
      where: fc.creative_id == ^creative_id,
      join: f in assoc(fc, :film),
      order_by: [desc: f.year],
      select: {f, fc.role, fc.subrole}
    )
    |> Repo.all()
  end

  defp already_claimed?(nil), do: false

  defp already_claimed?(user) do
    Repo.exists?(from c in Creative, where: c.user_id == ^user.id)
  end
end

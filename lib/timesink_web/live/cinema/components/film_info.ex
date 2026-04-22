defmodule TimesinkWeb.Components.FilmInfo do
  use Phoenix.Component

  alias Timesink.Cinema.{Film, Creative}

  attr :film, Film, required: true
  attr :class, :string, default: nil

  def film_info(assigns) do
    ~H"""
    <div id="film-info" class={["w-full mt-2 pt-3 pb-4", @class]}>
      <%!-- Title --%>
      <h2 class="text-2xl font-semibold tracking-wide text-mystery-white mb-3">
        {@film.title}
      </h2>

      <%!-- Genre pills + metadata --%>
      <div class="flex flex-wrap items-center gap-2 mb-4">
        <%= for genre <- @film.genres do %>
          <span class="inline-flex items-center rounded-full bg-zinc-600/30 border border-zinc-500/30 px-2.5 py-0.fo.ex
         -5 text-[11px] uppercase tracking-widest text-zinc-400">
            {genre.name}
          </span>
        <% end %>
        <%= if Enum.any?(@film.genres) and @film.duration do %>
          <span class="text-zinc-700">·</span>
        <% end %>
        <%= if @film.duration do %>
          <span class="text-xs text-zinc-500">{@film.duration} min</span>
        <% end %>
        <%= if @film.format do %>
          <span class="text-zinc-700">·</span>
          <span class="text-xs text-zinc-500 uppercase">{@film.format}</span>
        <% end %>
      </div>

      <%!-- Synopsis --%>
      <%= if @film.synopsis && @film.synopsis != "" do %>
        <p class="text-sm text-zinc-400 leading-relaxed font-light max-w-prose mb-6">
          {@film.synopsis}
        </p>
      <% end %>

      <%!-- Credits --%>
      <%= if Enum.any?(@film.directors) or Enum.any?(@film.writers) or Enum.any?(@film.producers) or Enum.any?(@film.cast) or Enum.any?(@film.crew) do %>
        <div class="border-t border-white/5 pt-4 space-y-2.5">
          <%= if Enum.any?(@film.directors) do %>
            <div class="flex gap-3 text-sm">
              <span class="text-[10px] uppercase tracking-widest text-zinc-600 pt-0.5 w-20 shrink-0">
                Director
              </span>
              <span class="text-zinc-300 font-light">
                <.creative_names film_creatives={@film.directors} />
              </span>
            </div>
          <% end %>
          <%= if Enum.any?(@film.writers) do %>
            <div class="flex gap-3 text-sm">
              <span class="text-[10px] uppercase tracking-widest text-zinc-600 pt-0.5 w-20 shrink-0">
                Writer
              </span>
              <span class="text-zinc-300 font-light">
                <.creative_names film_creatives={@film.writers} />
              </span>
            </div>
          <% end %>
          <%= if Enum.any?(@film.producers) do %>
            <div class="flex gap-3 text-sm">
              <span class="text-[10px] uppercase tracking-widest text-zinc-600 pt-0.5 w-20 shrink-0">
                Producer
              </span>
              <span class="text-zinc-300 font-light">
                <.creative_names film_creatives={@film.producers} />
              </span>
            </div>
          <% end %>
          <%= if Enum.any?(@film.cast) do %>
            <div class="flex gap-3 text-sm">
              <span class="text-[10px] uppercase tracking-widest text-zinc-600 pt-0.5 w-20 shrink-0">
                Cast
              </span>
              <span class="text-zinc-300 font-light">
                <.creative_names film_creatives={@film.cast} with_roles />
              </span>
            </div>
          <% end %>
          <%= if Enum.any?(@film.crew) do %>
            <div class="flex gap-3 text-sm">
              <span class="text-[10px] uppercase tracking-widest text-zinc-600 pt-0.5 w-20 shrink-0">
                Crew
              </span>
              <span class="text-zinc-300 font-light">
                <.creative_names film_creatives={@film.crew} with_roles />
              </span>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :film_creatives, :list, required: true
  attr :with_roles, :boolean, default: false

  defp creative_names(assigns) do
    ~H"""
    <span class="inline">
      <%= for {fc, idx} <- Enum.with_index(@film_creatives) do %>
        <%= if idx > 0 do %>
          <span class="mx-1.5 text-zinc-600">·</span>
        <% end %>
        <% path =
          if fc.creative.user,
            do: "/@#{fc.creative.user.username}",
            else: "/creatives/#{fc.creative.id}" %>
        <.link
          navigate={path}
          class={[
            "transition-colors underline-offset-2 hover:underline hover:decoration-zinc-400",
            if(fc.creative.user,
              do: "text-zinc-300 hover:text-white decoration-zinc-600",
              else: "text-zinc-500 hover:text-zinc-300 decoration-zinc-700"
            )
          ]}
        >
          {creative_label(fc, @with_roles)}
        </.link>
      <% end %>
    </span>
    """
  end

  defp creative_label(%{creative: c, subrole: r}, _with_roles = true) do
    name = Creative.full_name(c)
    if r && r != "", do: "#{name} (#{r})", else: name
  end

  defp creative_label(%{creative: c}, _with_roles), do: Creative.full_name(c)

  attr :film, Film, required: true

  attr :review_url, :string, default: nil

  def film_review(%{film: %{review: review}} = assigns) when is_binary(review) and review != "" do
    ~H"""
    <div id="film-review" class="px-1">
      <div class="flex items-center gap-3 mb-5">
        <div class="h-10 w-10 rounded-full overflow-hidden ring-1 ring-zinc-700 shrink-0">
          <img
            src="/images/timesink_hero.webp"
            alt="TimeSink"
            class="h-full w-full object-cover object-center"
          />
        </div>
        <div class="flex-1">
          <p class="text-sm font-medium text-mystery-white">TimeSink Presents</p>
          <p class="text-xs text-zinc-500">Film Review</p>
        </div>
        <button
          id="copy-review-link"
          phx-hook="CopyReviewLink"
          data-url={@review_url}
          title="Copy link to review"
          aria-label="Copy link to review"
          class="cursor-pointer group flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs text-zinc-500 ring-1 ring-zinc-700 hover:ring-zinc-500 hover:text-zinc-300 transition-all duration-200"
        >
          <span data-copy-icon>
            <svg
              class="w-3.5 h-3.5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="1.5"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244"
              />
            </svg>
          </span>
        </button>
      </div>
      <div class="film-review-body prose prose-invert prose-base max-w-none text-zinc-300 leading-relaxed prose-p:mt-4 prose-p:mb-6 prose-p:first-of-type:mt-0 prose-p:first-of-type:text-zinc-200">
        {Phoenix.HTML.raw(@film.review)}
      </div>
    </div>
    """
  end

  def film_review(assigns), do: ~H""
end

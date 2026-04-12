defmodule TimesinkWeb.Components.FilmInfo do
  use Phoenix.Component

  alias Timesink.Cinema.{Film, Creative}

  attr :film, Film, required: true
  attr :class, :string, default: nil

  def film_info(assigns) do
    ~H"""
    <div id="film-info" class={["w-full mt-2 pt-3 pb-4 space-y-4", @class]}>
      <div class="text-2xl font-semibold tracking-wide text-mystery-white">
        {@film.title}
      </div>

      <div class="text-xs md:text-sm text-mystery-white uppercase tracking-wider flex flex-wrap items-center gap-2">
        <%= for genre <- @film.genres do %>
          <span class="inline-block bg-dark-theater-primary rounded-full px-2 py-1 text-xs">
            {genre.name}
          </span>
        <% end %>

        <%= if Enum.any?(@film.genres) do %>
          <span>•</span>
        <% end %>
        <span>{@film.duration} min</span>
        <span>•</span>
        <span>{String.upcase(to_string(@film.format))}</span>
        <span>•</span>
        <span>{@film.aspect_ratio} aspect</span>

        <%= if @film.color do %>
          <span>•</span>
          <span class="capitalize">{String.replace(to_string(@film.color), "_", " ")}</span>
        <% end %>
      </div>

      <div class="text-base text-gray-300 leading-relaxed font-light max-w-prose">
        {@film.synopsis}
      </div>

      <div class="text-sm text-gray-400 font-light space-y-2 pt-4 border-t border-gray-900 mt-6">
        <%= if Enum.any?(@film.directors) do %>
          <div>
            <span class="text-gray-500 uppercase tracking-wider">Director:</span>
            <span class="text-gray-300"><.creative_names film_creatives={@film.directors} /></span>
          </div>
        <% end %>

        <%= if Enum.any?(@film.writers) do %>
          <div>
            <span class="text-gray-500 uppercase tracking-wider">Writer:</span>
            <span class="text-gray-300"><.creative_names film_creatives={@film.writers} /></span>
          </div>
        <% end %>

        <%= if Enum.any?(@film.producers) do %>
          <div>
            <span class="text-gray-500 uppercase tracking-wider">Producer:</span>
            <span class="text-gray-300"><.creative_names film_creatives={@film.producers} /></span>
          </div>
        <% end %>

        <%= if Enum.any?(@film.cast) do %>
          <div>
            <span class="text-gray-500 uppercase tracking-wider">Cast:</span>
            <div class="text-gray-300">
              <.creative_names film_creatives={@film.cast} with_roles />
            </div>
          </div>
        <% end %>

        <%= if Enum.any?(@film.crew) do %>
          <div>
            <span class="text-gray-500 uppercase tracking-wider">Crew:</span>
            <div class="text-gray-300">
              <.creative_names film_creatives={@film.crew} with_roles />
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :film_creatives, :list, required: true
  attr :with_roles, :boolean, default: false

  defp creative_names(assigns) do
    ~H"""
    <%= for {fc, idx} <- Enum.with_index(@film_creatives) do %>
      {if idx > 0, do: ", "}
      <%= if fc.creative.user do %>
        <.link
          navigate={"/@#{fc.creative.user.username}"}
          class="hover:text-mystery-white transition-colors"
        >
          {creative_label(fc, @with_roles)}
        </.link>
      <% else %>
        <.link
          navigate={"/creatives/#{fc.creative.id}"}
          class="hover:text-mystery-white transition-colors"
        >
          {creative_label(fc, @with_roles)}
        </.link>
      <% end %>
    <% end %>
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

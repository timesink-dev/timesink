defmodule TimesinkWeb.Components.FilmInfo do
  use Phoenix.Component

  alias Timesink.Cinema.{Film, Creative}

  attr :film, Film, required: true
  attr :class, :string, default: nil

  def film_info(assigns) do
    ~H"""
    <div
      id="film-info"
      class={["w-full mt-6 md:mt-8 border-t border-gray-800 pt-6 space-y-4", @class]}
    >
      <div class="text-2xl font-semibold tracking-wide text-mystery-white">
        {@film.title}
        <span class="text-gray-400 text-base ml-2">({@film.year})</span>
      </div>

      <div class="text-xs md:text-sm text-mystery-white uppercase tracking-wider flex flex-wrap gap-x-3 md:gap-x-4 gap-y-2">
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
end

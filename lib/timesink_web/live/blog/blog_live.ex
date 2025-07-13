defmodule TimesinkWeb.BlogLive do
  use TimesinkWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, %{posts: posts}} =
      GhostContent.config(:timesink)
      |> GhostContent.get_posts()

    IO.inspect(posts, label: "Fetched posts")

    {:ok, assign(socket, :posts, posts)}
  end

  def render(assigns) do
    ~H"""
    <section class="px-6 md:px-24 py-16">
      <div class="mb-12">
        <h1 class="text-md font-semibold text-gray-100 tracking-widest uppercase">
          Fresh off the press
        </h1>
        <p class="text-xs text-gray-400 mt-2">
          Featuring op-eds, stories, essays, and insights from guest authors and the TimeSink community
        </p>
      </div>

      <div class="space-y-12">
        <%= for post <- @posts do %>
          <article
            class="hover:cursor-pointer border-t border-t-dark-theater-medium border-t-[0.2px] pt-8"
            phx-click="navigate_to_post"
            phx-value-slug={post.slug}
          >
            <h2 class="text-gray-400 text-2xl font-semibold hover:underline mb-4 tracking-tight leading-snug">
              {post.title}
            </h2>
            
    <!-- Image + Excerpt row -->
            <div class="flex flex-col md:flex-row gap-6">
              <a href={~p"/blog/#{post.slug}"}>
                <img
                  src={post.feature_image}
                  alt={post.title}
                  class="w-full md:w-60 h-40 object-cover rounded-md"
                />
              </a>
              <div class="flex flex-col justify-between">
                <div>
                  <p class="italic text-gray-400 text-md w-2/3">
                    {if post.excerpt, do: String.slice(post.excerpt, 0, 160) <> "...", else: ""}
                  </p>
                  <%!-- <a
                    href={~p"/blog/#{post.slug}"}
                    class="mt-2 text-sm inline-block text-neon-blue-lightest hover:underline"
                  >
                    Read more →
                  </a> --%>
                </div>
                <div class="mt-4 text-xs text-dark-theater-light flex items-center justify-between">
                  <span>By {first_author(post)} — {format_date(post.published_at)}</span>
                  <div class="flex items-center gap-4">
                    <div class="flex items-center gap-1">
                      <.icon name="hero-eye" class="h-4 w-4" /> <span>—</span>
                    </div>
                    <div class="flex items-center gap-1">
                      <.icon name="hero-chat-bubble-left-ellipsis" class="h-4 w-4" /> <span>—</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </article>
        <% end %>
      </div>
    </section>
    """
  end

  # def first_author(post) do
  #   post.authors
  #   |> List.first()
  #   |> then(& &1.name)
  # end

  def handle_event("navigate_to_post", %{"slug" => slug}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/blog/#{slug}")}
  end

  defp first_author(post), do: post.primary_author || "Unknown"

  defp format_date(date) do
    date_string = to_string(date)
    {:ok, datetime, _offset} = DateTime.from_iso8601(date_string)
    {:ok, formatted_date} = Timex.format(datetime, "{Mshort} {D}, {YYYY}")
    formatted_date
  end
end

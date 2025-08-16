defmodule TimesinkWeb.BlogPostLive do
  use TimesinkWeb, :live_view

  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, %{posts: [post]}} =
      GhostContent.config(:timesink)
      |> GhostContent.get_post_by_slug(slug)

    IO.puts("Post: #{inspect(post)}")
    {:ok, assign(socket, :post, post)}
  end

  def format_date(date) do
    date_string = to_string(date)
    {:ok, datetime, _offset} = DateTime.from_iso8601(date_string)
    {:ok, formatted_date} = Timex.format(datetime, "{Mfull} {D}, {YYYY}")
    formatted_date
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <section class="mx-24 mb-24">
      <div class="flex flex-col items-start justify-start gap-y-1 my-20 mx-24">
        <span>{@post.tags}</span>
        <h1 class="ghost-blog-title font-gangster uppercase text-3xl my-4">{@post.title}</h1>
        <%!-- <span class="text-lg">{@post.excerpt}</span> --%>
        <div class="flex flex-col justify-start mt-4 mb-6 text-sm">
          <span>{@post.primary_author}</span>
          <span>{format_date(@post.published_at)}</span>
        </div>
      </div>
      <div class="mb-16">
        <img src={@post.feature_image} class="block mb-2 h-96 w-96 text-center mx-auto" />
        <span class="text-center italic flex justify-center">
          {raw(@post.feature_image_caption)}
        </span>
      </div>
      <div class="ghost-post first-letter:text-7xl first-letter:float-left first-letter:pr-1 mx-40">
        {raw(@post.html)}
      </div>
      <div class="mx-24">
        <div class="border-t border-dark-theater-medium my-8" />
        <h3 class="mt-6 mb-4">Comments</h3>
      </div>
    </section>
    """
  end
end

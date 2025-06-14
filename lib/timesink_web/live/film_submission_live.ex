defmodule TimesinkWeb.FilmSubmissionLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div
      id="film-submission"
      class="min-h-screen text-white px-6 md:px-12 py-16 md:py-24 flex flex-col-reverse md:flex-row items-center md:items-center gap-6"
    >
      
    <!-- Left Text Content -->
      <div class="w-full md:w-2/5">
        <h1 class="text-4xl md:text-5xl leading-tight font-brand text-white">
          Grow your Audience.
        </h1>
        <p class="text-xl mt-4 text-gray-300">$25.00 submission fee</p>

        <div class="mt-8 space-y-6 text-base text-gray-400 max-w-md">
          <p>
            TimeSink is a live cinema platform built for bold films and the people who love them.
          </p>
          <p>
            We welcome short and feature-length projects across all genres, styles, and moods.
          </p>
          <p>
            Every submission is carefully reviewed by our programming team. You’ll hear from us directly once a decision is made.
          </p>
          <p>
            Join a vibrant community of cinephiles, creators, and curious minds. Submit your work and be part of the conversation.
          </p>
        </div>

        <.link
          navigate={~p"/submit/new"}
          class="mt-10 inline-block bg-white text-black font-semibold px-6 py-3 rounded-lg shadow hover:bg-gray-200 transition"
        >
          Begin submission
        </.link>

        <%= if @current_user do %>
          <div class="mt-8 max-w-md">
            <p class="text-sm text-green-400 bg-green-600/20 p-3 rounded border border-green-500">
              You're signed in as {@current_user.email}. We’ll pre-fill your details.
            </p>
          </div>
        <% end %>
      </div>
      
    <!-- Right Image Panel -->
      <div class="w-full md:w-3/5">
        <div class="relative aspect-[4/3] md:aspect-video">
          <img
            src="/images/submit-2.png"
            alt="Film submission visual"
            class="w-full h-full object-cover rounded-xl shadow-lg"
          />
        </div>
      </div>
    </div>
    """
  end
end

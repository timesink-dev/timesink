defmodule TimesinkWeb.FilmSubmission.StepIntroComponent do
  use TimesinkWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <section class="w-full px-6">
      <div class="max-w-7xl mx-auto flex flex-col-reverse md:flex-row items-start gap-6 md:gap-24">
        <!-- Text Content -->
        <div class="w-full md:w-2/5">
          <h1 class="text-4xl md:text-5xl font-brand">
            This is your spotlight.
          </h1>
          <p class="text-lg mt-4 text-neon-blue-lightest font-medium">$25.00 submission fee</p>

          <div class="mt-8 space-y-6 text-base text-gray-300 max-w-prose">
            <p>
              Welcome to <strong>TimeSink Presents</strong> — our stage, your screen.
            </p>
            <p>
              We’re not just curating films — we’re curating moments. Intimate premieres. Global audiences. Real-time connection.
            </p>
            <p>
              Got a short that sparks? A feature that won’t be ignored? We want it. All genres. All tones. All visions — as long as they’re yours.
            </p>
            <p>
              Every submission gets a human review by our programming team. If it moves us, we’ll move mountains to share it.
            </p>
            <p>
              So go on. Submit your work. Step into the room. The lights are bright. The reel is rolling. The music is playing. The spotlight is yours.
            </p>
          </div>

          <.button
            color="primary"
            class="w-full md:w-1/2 py-3 text-lg mt-12 mb-4"
            phx-click={JS.push("go_to_step", value: %{step: "next"})}
          >
            Begin film submission
          </.button>

          <%= if @data.user do %>
            <div class="mt-8">
              <p class="text-sm text-green-300 bg-green-900/30 p-3 rounded border border-green-600">
                You're signed in as {"@" <> @data.user.username}. We’ll pre-fill your details.
              </p>
            </div>
          <% end %>
        </div>

    <!-- Image -->
        <div class="w-full md:w-3/5 self-center">
          <div class="w-full rounded-xl overflow-hidden">
            <img
              src="/images/UPSCALE REGISTRATION.png"
              alt="Film submission visual"
              class="w-full h-full object-cover"
            />
          </div>
        </div>
      </div>
    </section>
    """
  end

  def handle_event("begin_submission", _params, socket) do
    send(self(), {:go_to_step, :next})
    {:noreply, socket}
  end
end

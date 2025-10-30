defmodule TimesinkWeb.FilmSubmission.StepIntroComponent do
  use TimesinkWeb, :live_component

  def mount(socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <section class="w-full px-6">
      <div class="max-w-7xl mx-auto flex flex-col-reverse md:flex-row items-start gap-6 md:gap-24">
        <!-- Text Content -->
        <div class="w-full md:w-2/5">
          <h1 class="text-3xl font-brand">
            Film submissions
          </h1>
          <p class="text-lg mt-4 text-neon-blue-lightest font-medium">
            $25.00 submission fee
          </p>

          <div class="mt-8 space-y-4 text-base text-gray-300 max-w-prose">
            <p>TimeSink Presents screens for a live, global audience.</p>
            <p>All formats and genres welcome.</p>
            <p>
              <strong>
                Every submission gets a human review by our programming team from start to finish.
              </strong>
            </p>
            <p>If it moves us we’ll follow up with next steps.</p>
          </div>

          <.button
            color="primary"
            class="w-full md:w-1/2 py-3 text-lg mt-12 mb-4"
            phx-click={JS.push("go_to_step", value: %{step: "next"})}
          >
            Start submission
          </.button>

          <%= if @data.user do %>
            <div class="mt-8">
              <p class="text-sm text-green-300 bg-green-900/30 p-3 rounded border border-green-600">
                Signed in as {"@" <> @data.user.username}. We’ll pre-fill your details.
              </p>
            </div>
          <% end %>
        </div>
        
    <!-- Image -->
        <div class="w-full md:w-3/5 self-center">
          <div class="w-full rounded-xl overflow-hidden">
            <img
              src="/images/film_submission.webp"
              alt="Film submission visual"
              class="w-full h-full object-cover"
              loading="eager"
              decoding="async"
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

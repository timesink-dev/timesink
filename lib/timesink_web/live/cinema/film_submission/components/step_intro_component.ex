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
            Film submission
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
            <p>If it moves us we'll follow up with next steps.</p>
          </div>
          <.button
            color="primary"
            class="w-full lg:w-1/2 py-3 text-lg mt-8 mb-4"
            phx-click={JS.push("go_to_step", value: %{step: "next"})}
          >
            Begin submission
          </.button>
          <!-- Payment methods -->
          <div class="mt-8 space-y-2">
            <div class="flex items-center gap-2.5 text-xs text-gray-400">
              <span class="font-medium">We accept:</span>
              <div class="flex items-center gap-2">
                <div class="flex items-center gap-1.5 px-2.5 py-1 bg-gray-800/50 rounded-lg border border-gray-700/50">
                  <svg
                    class="w-3.5 h-3.5"
                    viewBox="0 0 24 24"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <rect
                      x="2"
                      y="5"
                      width="20"
                      height="14"
                      rx="2"
                      stroke="currentColor"
                      stroke-width="1.5"
                    />
                    <path d="M2 10h20" stroke="currentColor" stroke-width="1.5" />
                  </svg>
                  <span>Credit/Debit</span>
                </div>
                <div class="flex items-center gap-1.5 px-2.5 py-1 bg-orange-500/10 rounded-lg border border-orange-500/30">
                  <svg
                    class="w-3.5 h-3.5 text-orange-400"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M23.638 14.904c-1.602 6.43-8.113 10.34-14.542 8.736C2.67 22.05-1.244 15.525.362 9.105 1.962 2.67 8.475-1.243 14.9.358c6.43 1.605 10.342 8.115 8.738 14.548v-.002zm-6.35-4.613c.24-1.59-.974-2.45-2.64-3.03l.54-2.153-1.315-.33-.525 2.107c-.345-.087-.705-.167-1.064-.25l.526-2.127-1.32-.33-.54 2.165c-.285-.067-.565-.132-.84-.2l-1.815-.45-.35 1.407s.975.225.955.236c.535.136.63.486.615.766l-1.477 5.92c-.075.166-.24.406-.614.314.015.02-.96-.24-.96-.24l-.66 1.51 1.71.426.93.242-.54 2.19 1.32.327.54-2.17c.36.1.705.19 1.05.273l-.51 2.154 1.32.33.545-2.19c2.24.427 3.93.257 4.64-1.774.57-1.637-.03-2.58-1.217-3.196.854-.193 1.5-.76 1.68-1.93h.01zm-3.01 4.22c-.404 1.64-3.157.75-4.05.53l.72-2.9c.896.23 3.757.67 3.33 2.37zm.41-4.24c-.37 1.49-2.662.735-3.405.55l.654-2.64c.744.18 3.137.524 2.75 2.084v.006z" />
                  </svg>
                  <span class="text-orange-400 font-medium">Bitcoin</span>
                </div>
              </div>
            </div>
            <p class="text-xs text-gray-500 max-w-md leading-relaxed">
              Bitcoin because cinema deserves to be powered by permissionless money.
            </p>
          </div>
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

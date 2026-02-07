defmodule TimesinkWeb.ShowcaseInfoModalComponent do
  use TimesinkWeb, :live_component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="showcase-info-modal">
        <div class="space-y-6">
          <div class="border-b border-white/10 pb-5">
            <h2 class="text-xl md:text-2xl font-semibold text-white">
              What is a Showcase?
            </h2>
            <p class="mt-2 text-sm text-zinc-400 leading-relaxed">
              TimeSink doesn’t run an endless catalog. We run carefully curated “volumes.”
            </p>
          </div>

          <div class="space-y-4 text-sm text-zinc-300 leading-relaxed">
            <p>
              A <span class="text-white font-medium">Showcase</span>
              is a limited-time program, like a cinema’s weekly lineup,
              or a magazine edition. It has a loose theme and a point of view.
            </p>

            <div class="rounded-xl border border-white/10 bg-white/[0.03] p-4">
              <p class="text-white font-medium mb-2">How it works:</p>

              <ul class="space-y-2 text-zinc-300">
                <li class="flex gap-2 items-start">
                  <span class="mt-1 h-2 w-2 rounded-full bg-gray-400"></span>
                  <span>Each theater gets a fresh film for the volume.</span>
                </li>
                <li class="flex gap-2 items-start">
                  <span class="mt-1 h-2 w-2 rounded-full bg-gray-400 shrink-0"></span>
                  <span>Films screen on a periodic schedule. You watch together, in sync.</span>
                </li>
                <li class="flex gap-2 items-start">
                  <span class="mt-1 h-2 w-2 rounded-full bg-gray-400 shrink-0"></span>
                  <span>Sometimes we invite a guest curator to program a theater.</span>
                </li>
                <li class="flex gap-2 items-start">
                  <span class="mt-1 h-2 w-2 rounded-full bg-gray-400 shrink-0"></span>
                  <span>Live chat is part of the show, not an afterthought.</span>
                </li>
              </ul>
            </div>

            <p class="text-zinc-400">
              Think: fewer choices, more intention.
            </p>
          </div>

          <div class="flex flex-col sm:flex-row gap-3 pt-2">
            <button
              type="button"
              phx-click={show_modal("newsletter-modal")}
              class="inline-flex items-center justify-center rounded-full bg-white text-backroom-black px-4.5 py-2 text-sm font-medium transition hover:opacity-90 cursor-pointer"
            >
              Get notified for the next drop
            </button>
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end

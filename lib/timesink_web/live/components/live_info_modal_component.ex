defmodule TimesinkWeb.LiveInfoModalComponent do
  use TimesinkWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="live-info-modal">
        <div class="space-y-6">
          <div class="border-b border-white/10 pb-5">
            <p class="text-xs uppercase tracking-wider text-zinc-400">Live for every showing</p>
            <h2 class="mt-2 text-2xl font-semibold tracking-tight text-white">
              Same moment. Same room. Real conversation.
            </h2>
            <p class="mt-3 text-sm text-zinc-400 leading-relaxed">
              TimeSink is built like a cinema: you show up, the lights go down, and you’re watching with others —
              not “alone together” on a pause-and-scroll platform.
            </p>
          </div>

          <div class="space-y-3 text-sm text-zinc-300/90">
            <div class="rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <p class="font-medium text-white">Synchronized screenings</p>
              <p class="mt-1 text-zinc-400">
                Join in-progress and you’ll drop into the same timestamp as everyone else. No spoilers from people 30 minutes ahead.
              </p>
            </div>

            <div class="rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <p class="font-medium text-white">Chats that make a theater</p>
              <p class="mt-1 text-zinc-400">
                Smart, lightweight, and present. Enough to feel the room, but not enough to drown the film.
              </p>
            </div>

            <div class="rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <p class="font-medium text-white">Events when it matters</p>
              <p class="mt-1 text-zinc-400">
                Premieres, Q&amp;As, and one-night showings show up as showcases — not endless archives.
              </p>
            </div>
          </div>

          <div class="border-t border-white/10 pt-4">
            <p class="text-xs text-zinc-500">
              Less “content”. More nights you remember.
            </p>
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end

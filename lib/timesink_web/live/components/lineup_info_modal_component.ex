defmodule TimesinkWeb.LineupInfoModalComponent do
  use TimesinkWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="lineup-info-modal">
        <div class="space-y-6">
          <div class="border-b border-white/10 pb-5">
            <p class="text-xs uppercase tracking-wider text-zinc-400">Hand-picked lineup</p>
            <h2 class="mt-2 text-2xl font-semibold tracking-tight text-white">
              Curation with a point of view.
            </h2>
            <p class="mt-3 text-sm text-zinc-400 leading-relaxed">
              TimeSink isn’t an infinite feed. Every film is chosen with intention. For voice, craft, risk,
              and the feeling that it deserves a room full of people.
            </p>
          </div>

          <div class="space-y-3 text-sm text-zinc-300/90">
            <div class="rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <p class="font-medium text-white">Each theater a film.</p>
              <p class="mt-1 text-zinc-400">
                Each theater runs a single film at a time. The selection stays readable, intentional, and watchable.
              </p>
            </div>

            <div class="rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <p class="font-medium text-white">Guest curation, sometimes...</p>
              <p class="mt-1 text-zinc-400">
                Filmmakers and special guests can program a room. It might be a mini retrospective, a double-feature idea,
                or a theme they’re obsessed with.
              </p>
            </div>

            <div class="rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <p class="font-medium text-white">No “slop-proofing” needed</p>
              <p class="mt-1 text-zinc-400">
                If it’s on TimeSink, it already passed the first filter: it’s worth your time.
              </p>
            </div>
          </div>

          <div class="border-t border-white/10 pt-4">
            <p class="text-xs text-zinc-500">
              New showcases rotate like cinema programs — not like timelines.
            </p>
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end

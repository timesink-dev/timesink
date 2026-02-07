defmodule TimesinkWeb.CommunityInfoModalComponent do
  use TimesinkWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="community-info-modal">
        <div class="space-y-6">
          <div class="border-b border-white/10 pb-5">
            <p class="text-xs uppercase tracking-wider text-zinc-400">Global community</p>
            <h2 class="mt-2 text-2xl font-semibold tracking-tight text-white">
              A small world, on purpose.
            </h2>
            <p class="mt-3 text-sm text-zinc-400 leading-relaxed">
              TimeSink is for people who actually watch. You’ll find curious viewers, filmmakers, and regulars —
              across timezones — all meeting in the same rooms.
            </p>
          </div>

          <div class="space-y-3 text-sm text-zinc-300/90">
            <div class="rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <p class="font-medium text-white">Presence, not follower counts</p>
              <p class="mt-1 text-zinc-400">
                Rooms show who’s here right now. It’s closer to a venue than a social feed.
              </p>
            </div>

            <div class="rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <p class="font-medium text-white">Conversation with context</p>
              <p class="mt-1 text-zinc-400">
                You’re discussing the same film, sometimes at the same moment. That alone raises the signal-to-noise ratio. Often the best discoveries are word-of-mouth.
              </p>
            </div>

            <div class="rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <p class="font-medium text-white">Built to meet people</p>
              <p class="mt-1 text-zinc-400">
                Drop into a theater, recognize names, become a regular. The goal is a culture. Not an audience metric.
              </p>
            </div>
          </div>

          <div class="border-t border-white/10 pt-4">
            <p class="text-xs text-zinc-500">
              Come for the film, stay for the people and conversation. You never know who you’ll meet in the room.
            </p>
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end

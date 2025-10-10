defmodule TimesinkWeb.InfoPageLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <% year = Date.utc_today().year %>

    <section class="max-w-3xl mx-auto px-6 py-16 space-y-12">
      <% ## TODO include note on amount of theaters -- and why %>
      <h1 class="text-4xl font-brand text-white text-center">FAQs</h1>

      <div class="space-y-10 text-gray-300 text-sm leading-relaxed">
        <div>
          <h2 class="text-white font-semibold text-lg">What is TimeSink?</h2>
          <p class="mt-1">
            TimeSink is an electronic theater, lounge, and broadcast for people who still care about cinema. Not the algorithm-churned sludge—actual films, chosen with taste and guts. We host curated, time-based screenings where you show up, tune in, and watch something with other humans. Yes, in {year}.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">
            Why should I care when I already have Netflix / Mubi / YouTube / etc?
          </h2>
          <p class="mt-1">
            You don’t need another endless scroll. TimeSink isn’t a content warehouse—it’s an actual theater. Think: one screen, one showing, one moment. The kind of place that *might’ve* shown Kubrick’s *Fear and Desire* back in ’53—just once, then quietly moved on. (Hey, we love the guy, but even genius starts somewhere.) We champion the bold, the fresh, the actually-watchable. No autoplay. No binging. No algorithm. Just cinema that earns your attention. The anti-content antidote—with modern flavor and zero tolerance for mediocrity.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">Who chooses the films?</h2>
          <p class="mt-1">
            We do. Carefully. No bots, no buy-ins. We watch everything, argue over it, and only show what we genuinely believe is worth your time. These aren’t dusty festival leftovers—these are firecrackers, dream bombs, midnight gems, and micro-masterpieces.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">What kind of stuff do you show?</h2>
          <p class="mt-1">
            Short films, features, docs, hybrids, experiments. Bold stories told well. We don’t care if it’s shot on an iPhone or a Bolex—if it moves us (or melts our brain), it’s in. The only rule? No boring and no pandering.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">Is this just for filmmakers?</h2>
          <p class="mt-1">
            Nah, not a chance!
            It’s for CEOs, janitors, folks who just dance.
            For night shift snackers and log-sitting thinkers,
            For dreamers, schemers, and popcorn-flingers.

            If you like movies, you’re already in—
            So grab your seat and let madness begin!
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">
            Can I sign up and become a member right away?
          </h2>
          <p class="mt-1">
            Not quite. TimeSink runs on a rolling-access model — meaning there’s a waitlist. Why? Because intimacy matters. We’re not chasing raw traffic; we’re building a shared experience, one audience at a time. Everyone watches together, so we only let in a limited number of new members per wave. Think velvet rope, not open bar. But once you’re in, you’re in. Your spot is yours. No algorithms, no chaos — just real cinema, with real people, on your wavelength.
          </p>
          <p class="mt-3">
            <span class="font-semibold"> Ready to join? </span>
            <a href="/join" class="text-gray-400 border-b-[0.5px] pb-1">Get in line here 🎟️ →</a>
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">What happens if my film gets selected?</h2>
          <p class="mt-1">
            First, congrats—you made something we actually like. That’s rare. And you’ll get something rarer: a real showing. Not buried in a catalog. Not just “content.” A proper screening, live, with a real-time audience watching, chatting, reacting. We're building toward filmmaker rewards like revenue sharing, direct support, and even investor access—because the future of cinema should actually support its creators.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">
            Do I have to be a member to submit a film?
          </h2>
          <p class="mt-1">
            Nope. Anyone can submit a film. But members get perks—like tracking their submission status in a personal dashboard. If your film is selected, your profile becomes part of the presentation: full creator credit, a public page, and a badge that links to your work (think IMDb, but cooler).
          </p>
          <p class="mt-3">
            <span class="font-semibold"> Ready to submit? </span>
            <a href="/submit" class="text-gray-400 border-b-[0.5px] pb-1">
              Submit your film here 📼 →
            </a>
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">
            Will submitting to TimeSink hurt my chances with major festivals?
          </h2>
          <p class="mt-1">
            Doubtful. Our films play in electronic theaters — not on the open internet. Only signed-in members can attend. There’s no replay, no public link, no algorithm shelf. Like Duchamp said: <em>the viewer completes the work</em>. And as T.S. Eliot put it, <em>art doesn’t exist in a vacuum — its meaning is shaped by what surrounds it</em>. Festivals? Most are cool with that kind of limited, contextual screening. When in doubt, check the fine print. We’re building buzz, not burning bridges.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">Do you do real-world events?</h2>
          <p class="mt-1">
            Not yet—but we’re planning them. Pop-up screenings, rooftop shows, underground cinemas. Think flickering projectors, midnight premieres, and a crowd that’s actually into it. Our dream is to bring the spirit of TimeSink off the screen and into real, electric rooms.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">How much does it cost to submit a film?</h2>
          <p class="mt-1">
            $25. That covers infrastructure, screening tools, curation, and maybe coffee. We don’t charge for fun.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">When will I hear back?</h2>
          <p class="mt-1">
            Usually within 4–6 weeks. If you haven’t heard after that, we’re either discussing your film… or arguing about it. We’ll let you know.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">
            Does TimeSink make money?
          </h2>
          <p class="mt-1">
            Not yet. We charge a submission fee — mostly to keep the lights on. This wasn’t exactly a shark-tank-ready business idea, and we’re fine with that. TimeSink wasn’t built for churn funnels or banner ads. But yeah, we’d like it to become a real business one day. Maybe that means tasteful sponsorships, partnerships, pay-per-view premieres, limited merch, or community-backed awards. Whatever it is, it won’t mess with the experience. Advertisers don’t shape this — the audience and the films do. If they come, it’s on our terms.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">What’s the big picture?</h2>
          <p class="mt-1">
            TimeSink is building a culture, not a catalog. We're here for people who miss the edge, who want discovery, who want to watch beautiful things with other people again. If that’s you—welcome home.
          </p>
        </div>
      </div>
    </section>
    """
  end
end

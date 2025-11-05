defmodule TimesinkWeb.InfoPageLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <section class="max-w-3xl mx-auto px-6 py-16 space-y-12">
      <% ## TODO include note on amount of theaters -- and why %>
      <h1 class="text-4xl font-brand text-white text-center">FAQs</h1>

      <div class="space-y-10 text-gray-300 text-sm leading-relaxed">
        <div>
          <h2 class="text-white font-semibold text-lg">What is TimeSink?</h2>
          <p class="mt-1">
            TimeSink is a virtual cinema for people who are curious about film. We host curated, time-based screenings. Just show up at showtime and watch something worth your attention.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">
            Why should I care when there are other platforms like Netflix / YouTube / etc?
          </h2>
          <p class="mt-1">
            Because those are content libraries finely-tuned by machines. TimeSink is a theater. One screen, one showing, one moment shared with others. No autoplay, no algorithm recommendations, no binging. We curate bold, distinctive films that earn your time. If you're tired of scrolling and want cinema that actually moves you, this is it.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">Who chooses the films?</h2>
          <p class="mt-1">
            We do. Our team watches everything, debates it, and only screens what we genuinely believe deserves an audience. No bots, no algorithms, no pay-to-play. Just passionate curation focused on bold storytelling and genuine craft.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">What kind of films do you show?</h2>
          <p class="mt-1">
            Short films, features, documentaries, comedies, hybrids, experiments—anything with a strong voice and vision. Format doesn't matter. iPhone or cinema camera, we don't care. If it's compelling and well-made, it's in. The only rule: no boring, no pandering.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">Who is this platform for?</h2>
          <p class="mt-1">
            Anyone who actually loves film. Filmmakers, cinephiles, curious viewers, night owls looking for something real. You don't need credentials or film school pedigree. If you're tired of algorithm-fed content and want to discover bold cinema with a community that gets it, you belong here.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">
            Can I join immediately?
          </h2>
          <p class="mt-1">
            Yes we are currently rolling out our early access phase. Sign up and you're in. Once you create an account, you'll have immediate access to our virtual theaters and upcoming screenings. But this won't last forever.
          </p>
          <p class="mt-3">
            <span class="font-semibold"> Ready to join? </span>
            <a href="/join" class="text-gray-400 border-b-[0.5px] pb-1">Sign up here 🎟️ →</a>
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">What happens if my film gets selected?</h2>
          <p class="mt-1">
            Your film gets a proper screening with a live audience, instead of being buried in a content library. You'll receive full creator credit, a public profile page, and exposure to engaged viewers who actually care. We're building toward filmmaker rewards including revenue sharing and direct support, because cinema should support its creators.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">
            Do I have to be a member to submit a film?
          </h2>
          <p class="mt-1">
            No. Anyone can submit. Members get perks like tracking their submission status through a personal dashboard. If selected, you'll get a creator profile with full credit and a public page showcasing your work.
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
            Will this affect my festival eligibility?
          </h2>
          <p class="mt-1">
            Unlikely. TimeSink screenings are private, member-only events. These are not public internet releases. There's no replay, no public link, no on-demand archive. Most festivals consider this kind of limited screening acceptable. Check your specific festival's rules, but we're designed to build buzz, not burn bridges.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">Do you host in-person events?</h2>
          <p class="mt-1">
            Not yet, but it's in the plans. Pop-up screenings, midnight premieres, underground cinema nights—bringing the TimeSink experience into physical spaces with audiences who care. Stay tuned.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">How much does it cost to submit a film?</h2>
          <p class="mt-1">
            $25. This covers our infrastructure, curation process, and screening tools.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">When will I hear back about my submission?</h2>
          <p class="mt-1">
            Typically witih a few days. If it takes longer, we're either deeply considering your film or debating it. Either way, you'll hear from us.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">
            Is TimeSink profitable?
          </h2>
          <p class="mt-1">
            Not yet. Currently, submission fees help cover costs. We're building something meaningful first, monetization second. Future revenue may come from sponsorships, premieres, or community support, but it won't compromise the experience. This platform serves the films and the audience, not advertisers.
          </p>
        </div>

        <div>
          <h2 class="text-white font-semibold text-lg">What's the vision?</h2>
          <p class="mt-1">
            We're building a culture around cinema, not just another streaming catalog. TimeSink is for people who want discovery, community, and films that matter. If that resonates then welcome... we're glad you've made it here.
          </p>
        </div>
      </div>
    </section>
    """
  end
end

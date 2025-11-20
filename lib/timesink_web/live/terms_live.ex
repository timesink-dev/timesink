defmodule TimesinkWeb.TermsPageLive do
  use TimesinkWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Terms of Service")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="max-w-4xl mx-auto px-6 sm:px-8 py-12 sm:py-16 text-mystery-white">
      <div class="mb-10 space-y-2">
        <p class="text-xs uppercase tracking-[0.2em] text-zinc-400 font-semibold">
          Legal
        </p>
        <h1 class="text-3xl sm:text-4xl font-semibold font-brand">
          Terms of Service
        </h1>
        <p class="text-xs sm:text-sm text-zinc-400">
          Last updated: November 20, 2025
        </p>
      </div>

      <div class="space-y-8 text-sm sm:text-base leading-relaxed text-zinc-100">
        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">1. Overview</h2>
          <p>
            TimeSink Presents, owned and operated by Aaron Zomback
            (“TimeSink”, “we”, “our”, or “us”) is a curated online cinema platform
            that hosts scheduled screenings of films with live chat, community
            features, and filmmaker submissions.
          </p>
          <p>
            By accessing or using TimeSink, you agree to be bound by these Terms of Service
            (“Terms”). If you do not agree, you may not use the platform.
          </p>
          <p>
            TimeSink is intended for individuals aged <strong>18 years or older</strong> only.
            By using the Service, you confirm that you meet this requirement.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">2. Eligibility & Accounts</h2>
          <p>
            To use certain features (including joining screenings, chatting, submitting films,
            or purchasing access), you must create an account and complete onboarding steps
            such as email verification and providing basic profile information.
          </p>
          <p>You agree to:</p>
          <ul class="list-disc list-inside space-y-1">
            <li>Provide accurate and truthful information.</li>
            <li>Maintain the confidentiality of your login credentials.</li>
            <li>Notify us promptly of any unauthorized use of your account.</li>
          </ul>
          <p>
            We may suspend or terminate accounts that violate these Terms or pose a security,
            legal, or community risk.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">3. Screenings & Streaming</h2>
          <p>
            TimeSink hosts scheduled screenings of films in virtual theaters with synchronized
            playback. Some features, such as seeking or rewinding, may be limited or disabled
            to preserve the shared viewing experience.
          </p>
          <p>You agree that you will not:</p>
          <ul class="list-disc list-inside space-y-1">
            <li>Download, copy, record, or redistribute streamed films.</li>
            <li>Bypass, disable, or interfere with any security or access controls.</li>
            <li>Share your account to avoid ticketing, membership, or capacity limits.</li>
          </ul>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">4. Filmmaker Submissions</h2>
          <p>
            If you submit a film or related materials to TimeSink (including posters, stills,
            and synopses):
          </p>
          <ul class="list-disc list-inside space-y-1">
            <li>
              You retain <strong>100% ownership and copyright</strong> in your film and
              materials.
            </li>
            <li>
              You grant TimeSink a <strong>non-exclusive, worldwide, revocable license</strong>
              to host, stream, and exhibit your film within the platform, and to display its
              title, poster, and basic metadata for programming, discovery, and promotion of
              the exhibition.
            </li>
            <li>
              You represent and warrant that you have all necessary rights and permissions
              to grant this license and that your submission does not infringe the rights
              of any third party.
            </li>
          </ul>
          <p>
            You may request removal of your film by contacting us. We will make reasonable
            efforts to remove it from future programming, but screenings already in progress
            or heavily promoted may still occur unless otherwise required by law.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">5. Payments & Refunds</h2>
          <p>
            TimeSink may charge for access to certain screenings, memberships, or submission
            fees. Payments are processed by third-party providers such as Stripe; we do not
            store full credit card numbers on our own servers.
          </p>
          <p>
            Except where <strong>required by applicable law</strong>, all payments are
            <strong>non-refundable</strong>. At our sole discretion, we may offer alternative
            access (for example, rescheduling a screening) if a show is materially disrupted
            by technical issues.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">6. Community Conduct</h2>
          <p>
            TimeSink includes live chat and other community features. You agree not to use the
            platform to:
          </p>
          <ul class="list-disc list-inside space-y-1">
            <li>Harass, threaten, or abuse other users or filmmakers.</li>
            <li>Post illegal, defamatory, hateful, or infringing content.</li>
            <li>Share spam, scams, or misleading promotions.</li>
            <li>
              Attempt to gain unauthorized access to accounts, systems, or private data.
            </li>
          </ul>
          <p>
            We may moderate, remove, or restrict content and accounts to protect the community
            and comply with legal obligations.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">7. Intellectual Property</h2>
          <p>
            Aside from filmmaker-submitted content, all materials on TimeSink—including our
            name, logo, branding, design, layout, text, code, and other assets—are owned by
            TimeSink Presents or its licensors and are protected by copyright and other laws.
          </p>
          <p>
            You may not reproduce, distribute, or create derivative works from our materials
            without our prior written consent.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">8. Third-Party Services</h2>
          <p>
            We rely on third-party providers such as Mux (video hosting/streaming), Stripe
            (payments), Resend (email), HERE Maps (location services), and cloud hosting
            providers. Your use of TimeSink may involve their services, which are subject
            to their own terms and privacy policies.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">9. Disclaimers</h2>
          <p>
            TimeSink is provided on an “as is” and “as available” basis without warranties of
            any kind, whether express or implied. We do not guarantee uninterrupted or
            error-free operation, or that content will always be available at a particular
            time or in a particular region.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">10. Limitation of Liability</h2>
          <p>
            To the fullest extent permitted by law, TimeSink and its owners shall not be liable
            for any indirect, incidental, special, or consequential damages arising out of or
            in connection with your use of the Service.
          </p>
          <p>
            Where our liability cannot be excluded, it is limited to the amount you have paid
            to TimeSink in the twelve (12) months preceding the event giving rise to the claim.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">11. Governing Law</h2>
          <p>
            These Terms are governed by and construed in accordance with the laws of the
            <strong>State of New York, USA</strong>, without regard to its conflict-of-law
            principles.
          </p>
          <p>
            If you are located in the EU/EEA or another jurisdiction with consumer protection
            rules, we also comply with any mandatory local rights you have, but legal disputes
            will be resolved under New York law where permissible.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">12. Changes to These Terms</h2>
          <p>
            We may update these Terms from time to time. When we make material changes, we
            will notify you via the platform or by email. Your continued use of TimeSink after
            changes take effect constitutes acceptance of the updated Terms.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">13. Contact</h2>
          <p>
            If you have questions about these Terms, you can reach us at:
          </p>
          <p class="font-gangster text-sm">
            hello@timesinkpresents.com
          </p>
        </section>
      </div>
    </section>
    """
  end
end

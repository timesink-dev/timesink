defmodule TimesinkWeb.PrivacyPageLive do
  use TimesinkWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Privacy Policy")}
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
          Privacy Policy
        </h1>
        <p class="text-xs sm:text-sm text-zinc-400">
          Last updated: November 20, 2025
        </p>
      </div>

      <div class="space-y-8 text-sm sm:text-base leading-relaxed text-zinc-100">
        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">1. Overview</h2>
          <p>
            This Privacy Policy explains how TimeSink Presents, owned and operated by
            Aaron Zomback (“TimeSink”, “we”, “our”, or “us”) collects, uses, and protects
            your personal information when you use our online cinema platform.
          </p>
          <p>
            We take privacy seriously. We do not sell your personal data and we only
            collect what we need to operate and improve the Service.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">2. Information We Collect</h2>
          <h3 class="font-semibold text-sm sm:text-base">2.1 Information you provide</h3>
          <ul class="list-disc list-inside space-y-1">
            <li>Email address and password.</li>
            <li>Name, username, and basic profile information.</li>
            <li>Birthdate (to confirm you are 18+).</li>
            <li>City, region, and country (via onboarding).</li>
            <li>Film submission details, including links, passwords, and metadata.</li>
            <li>Messages you send in chat, comments, or feedback forms.</li>
          </ul>

          <h3 class="font-semibold text-sm sm:text-base pt-3">2.2 Information collected automatically</h3>
          <ul class="list-disc list-inside space-y-1">
            <li>IP address and rough location derived from it.</li>
            <li>Device type, browser, and operating system.</li>
            <li>Usage data such as pages viewed, screenings joined, and timestamps.</li>
            <li>Presence information (e.g., which theater you’re currently in).</li>
            <li>
              Cookies or similar technologies used for authentication, preferences,
              and basic analytics.
            </li>
          </ul>

          <h3 class="font-semibold text-sm sm:text-base pt-3">2.3 Information from third parties</h3>
          <ul class="list-disc list-inside space-y-1">
            <li>Location suggestions from HERE Maps when you search for your city.</li>
            <li>Payment status and limited billing details from Stripe.</li>
            <li>Streaming and playback telemetry from Mux.</li>
            <li>Email delivery and engagement data from Resend.</li>
          </ul>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">3. How We Use Your Information</h2>
          <ul class="list-disc list-inside space-y-1">
            <li>To create and manage your account.</li>
            <li>To verify your email and secure your sessions.</li>
            <li>To provide access to screenings, chat, and other features.</li>
            <li>To process payments and maintain records where required by law.</li>
            <li>To operate, maintain, and improve the platform’s performance.</li>
            <li>To protect against fraud, abuse, and security threats.</li>
            <li>To communicate with you about exhibitions, updates, and support.</li>
          </ul>
          <p>
            We process personal data only when we have a legal basis to do so, including
            contract necessity, legitimate interests, legal obligations, or your consent
            (for example, for newsletters or certain cookies).
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">4. Sharing Your Information</h2>
          <p>
            We share your data only with trusted service providers who help us run the
            platform, such as:
          </p>
          <ul class="list-disc list-inside space-y-1">
            <li>Mux – video hosting and streaming.</li>
            <li>Stripe – payment processing.</li>
            <li>Resend – transactional email delivery.</li>
            <li>HERE Maps – location autocomplete services.</li>
            <li>
              Hosting and infrastructure providers (for example, Fly.io, AWS, or similar).
            </li>
          </ul>
          <p>
            These providers are contractually required to protect your data and use it
            only for the services they provide to us.
          </p>
          <p>
            We may also disclose information when required by law, court order, or to
            protect our rights, users, or the public.
          </p>
          <p>
            We <strong>do not sell</strong> your personal information to third parties.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">5. International Data Transfers</h2>
          <p>
            Because our infrastructure and providers may be located in different countries,
            your data may be processed outside of your country of residence, including in
            the United States and the European Union.
          </p>
          <p>
            When we transfer personal data from the EU/EEA or other regions with data
            protection laws, we use appropriate safeguards such as Standard Contractual
            Clauses or equivalent agreements where required.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">6. Data Retention</h2>
          <p>
            We keep your personal information only for as long as necessary to provide
            the Service and to meet legal, accounting, or reporting requirements.
          </p>
          <ul class="list-disc list-inside space-y-1">
            <li>Account data: kept while your account is active or until you request deletion.</li>
            <li>Email verification codes: kept for a short period (minutes) until they expire.</li>
            <li>Invite or access tokens: kept until used or expired.</li>
            <li>
              Playback and presence logs: kept for a limited operational window to monitor
              performance and security.
            </li>
            <li>Film submission data: kept while your film is programmed or hosted, or until you request removal.</li>
          </ul>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">7. Your Rights</h2>
          <p>
            Depending on where you live, you may have rights over your personal data,
            including the right to:
          </p>
          <ul class="list-disc list-inside space-y-1">
            <li>Access the personal data we hold about you.</li>
            <li>Request correction of inaccurate or incomplete data.</li>
            <li>Request deletion of your data, subject to legal obligations.</li>
            <li>Object to certain types of processing or request restriction.</li>
            <li>Request a copy of your data in a portable format.</li>
            <li>Withdraw consent where processing is based on consent.</li>
          </ul>
          <p>
            To exercise your rights, contact us at
            <span class="font-gangster">hello@timesinkpresents.com</span>.
            We will respond within a reasonable time and within any deadlines required by law.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">8. Security</h2>
          <p>
            We use reasonable technical and organizational measures to protect your data,
            including HTTPS encryption, secure password hashing, and access controls on
            our systems and services.
          </p>
          <p>
            No online service can be completely secure, but we work to protect your
            information and review our safeguards as the platform evolves.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">9. Cookies & Similar Technologies</h2>
          <p>
            We use cookies and similar technologies to keep you logged in, remember your
            preferences, support playback features, and measure basic usage of the platform.
          </p>
          <p>
            You can usually control cookies through your browser settings. If you disable
            certain cookies, some features of TimeSink may not work properly.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">10. Age Requirement</h2>
          <p>
            TimeSink is intended for users aged <strong>18 and over</strong>. We do not
            knowingly collect personal data from minors. If you believe a minor has
            registered or provided personal data, please contact us so we can remove it.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">11. Changes to This Policy</h2>
          <p>
            We may update this Privacy Policy from time to time. If we make material
            changes, we will notify you via the platform or by email. The “Last updated”
            date at the top will always reflect the current version.
          </p>
        </section>

        <section class="space-y-3">
          <h2 class="text-lg sm:text-xl font-semibold">12. Contact</h2>
          <p>
            If you have questions or concerns about this Privacy Policy or how we handle
            your data, you can contact us at:
          </p>
          <p class="font-gangster text-sm">
            privacy@timesinkpresents.com
          </p>
        </section>
      </div>
    </section>
    """
  end
end

defmodule Timesink.Waitlist.Mail do
  use Timesink.Mailer

  def send_waitlist_confirmation(to_email, first_name) do
    subject = "Welcome to TimeSink: you're on the waitlist"

    body = """
    Hi #{first_name},

    Thanks for signing up for early access to TimeSink. You’re officially on the waitlist.

    We introduce new members gradually as we shape the community and programming, and we’ll email you as soon as your spot opens.

    In the meantime, you can get a feel for what we’re building at our blog on our Substack, where we share programming notes, editorials, critiques, and film analysis:
    https://timesinkpresents.substack.com/

    If you have any questions, just reply to this email.

    TimeSink
    """

    html = TimesinkWeb.WaitlistConfirmationEmail.render_to_html(first_name)
    send_mail(to_email, subject, body, html)

    notify_internal(
      "New waitlist signup: #{first_name}",
      "#{first_name} (#{to_email}) just joined the waitlist."
    )
  end

  def send_invite_code(to_email, first_name, code) do
    subject = "Your invitation to join TimeSink"
    invite_url = "#{base_url()}/invite/#{code}"

    body = """
    Hi #{first_name},

    Great news! Your spot is ready. You’re now officially invited to join TimeSink.

    Click the link below to create your account and step inside:
    #{invite_url}

    We’re glad to have you with us.

    TimeSink
    """

    html = TimesinkWeb.InviteEmail.render_to_html(first_name, invite_url)

    send_mail(to_email, subject, body, html)
  end

  def send_platform_greeting(to_email, first_name, last_name) do
    subject = "Welcome to TimeSink. You've made it here at the beginning."

    body = """
    Hi #{first_name},

    Welcome to TimeSink. I'm really glad you're here.

    TimeSink was built around a simple idea: a film shouldn't have to end the moment it does.

    You leave a screening still thinking, still feeling, still wanting to talk about what you just saw — but most of the time, that energy has nowhere to go. The lights come up, people scatter, and whatever was sparked in the room disappears too quickly.

    TimeSink is built to hold onto that.

    It also provides a stage for filmmakers. Musicians have countless stages to share their work. Cinema deserves more spaces like that too — especially for films that need the right room, the right context, and the right audience.

    What matters here isn’t budget, scale, or access — just whether something is worth experiencing and talking about. That can come from anywhere.

    Just as importantly, I want TimeSink to grow into a rich community of viewers, creators, programmers, and curious people from all over the world — connecting through cinema, ideas, taste, disagreement, interpretation, and discovery. As Duchamp said, the viewer completes the work. Film doesn't only live on the screen, but in the response it creates and the conversation it opens.

    You're joining early, as everything is beginning to take shape.

    Here's where we're going:

    * Curated film showcases, each with its own theater room
    * Shared screenings that bring people into the same experience together
    * A vibrant chat where conversations don't die on the sidewalk
    * Audience notes attached to specific moments in a film, appearing as it plays so others can experience what you saw or felt
    * Director commentary presented in the same way, tied directly to moments in the film
    * A home for filmmakers to present work and for viewers to respond
    * An arthouse cinema built for connecting, not scrolling

    We've also opened a Substack where we'll publish editorials, film notes, and behind-the-scenes writing around the films and ideas that shape the platform:
    https://timesinkpresents.substack.com/

    TimeSink is small right now, intentionally.
    I'm building it slowly and carefully, with the goal of shaping something distinctive, alive, and lasting.

    This is just the beginning. As the next showcases and premieres take shape, you'll hear from us.

    Thanks for being here early.

    See you in the theater,
    Aaron
    Founder, TimeSink

    P.S. If you ever want to share thoughts, ideas, or just say hi, hit reply. I'll read everything.
    """

    html = TimesinkWeb.PlatformGreetingEmail.render_to_html(first_name)
    send_mail(to_email, subject, body, html)

    notify_internal(
      "New member signup: #{first_name} #{last_name}",
      "#{first_name} #{last_name} (#{to_email}) just completed registration."
    )
  end

  defp base_url do
    Application.fetch_env!(:timesink, :base_url)
  end
end

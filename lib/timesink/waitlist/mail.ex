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

    The TimeSink Team
    """

    send_mail(to_email, subject, body)
  end

  def send_invite_code(to_email, first_name, code) do
    subject = "Your invitation to join TimeSink"

    body = """
    Hi #{first_name},

    Great news! Your spot is ready. You’re now officially invited to join TimeSink.

    Click the link below to create your account and step inside:
    #{base_url()}/invite/#{code}

    We’re glad to have you with us.

    The TimeSink Team
    """

    send_mail(to_email, subject, body)
  end

  def send_platform_greeting(to_email, first_name) do
    subject = "Welcome to TimeSink — you’re here at the beginning"

    body = """
    Hi #{first_name},

    Welcome to TimeSink. I’m genuinely glad you’re here.

    This platform started years ago in the mid-to-late 2010's, when I was an ambitious young filmmaker living in New York City, doing what so many of us do: chasing the sparks of ideas, trying to bridge that impossible distance between the desire to create and the moment something finally takes shape.

    I spent countless nights at Anthology Film Archives, watching films that rattled me awake. I’d leave the theater buzzing. Wanting to talk, to debate, to stay in that feeling. But the moment the doors opened, the energy dissipated onto the street. Everyone walked off into the night, and the conversation evaporated with them.

    There was nowhere to go that wasn’t just a bar.
    Nowhere to linger with meaning.
    Nowhere for that spark to land.

    TimeSink grew out of that missing space.

    A place for the afterglow.
    A place where cinema doesn’t end when the credits roll.
    A place where the buzzing, fragile, electric thing that happens inside a theater can actually live a little longer — through conversation, through community, through other people who felt something too.

    You’re joining us very early.
    There are no showcases yet.
    But you’re exactly on time.

    Here’s where we’re going:

    * Curated film showcases, each with its own theater room
    * “Simulated live” screenings where everyone watches together in sync
    * A vibrant chat where conversations don’t die on the sidewalk
    * A home for filmmakers to share work and viewers to share reactions
    * A virtual arthouse cinema built for lingering, not scrolling

    TimeSink is small right now. This is intentional.
    It’s personal, handmade, and growing slowly, like all meaningful communities do.

    This is just the beginning. As we bring the first films, showcases, and premieres onto the platform, you’ll hear from us. Thank you for being here at the start. Your presence here is immense.

    Thank you for stepping inside at this early moment.
    Thank you for helping shape what this becomes.
    And thank you for believing, even a little, in the idea behind it.

    See you in the theater,
    Aaron
    Founder, TimeSink

    P.S. If you ever want to share thoughts, ideas, or just say hi, hit reply — I read everything.
    """

    send_mail(to_email, subject, body)
  end

  defp base_url do
    Application.fetch_env!(:timesink, :base_url)
  end
end

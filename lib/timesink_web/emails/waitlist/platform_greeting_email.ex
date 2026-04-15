defmodule TimesinkWeb.PlatformGreetingEmail do
  use Phoenix.Component
  import TimesinkWeb.EmailComponents

  def render(assigns) do
    ~H"""
    <.layout>
      <p style="margin:0 0 24px;font-size:22px;font-weight:normal;color:#e8e8e8;font-family:'Gangster Grotesk',Georgia,serif;letter-spacing:0.05em;">
        Welcome to TimeSink.
      </p>

      <p style="margin:0 0 16px;">Hi {@first_name},</p>

      <p style="margin:0 0 16px;">Welcome to TimeSink. We're really glad you're here.</p>

      <p style="margin:0 0 16px;">
        TimeSink was built around a simple idea: a film shouldn't have to end the moment it does.
      </p>

      <p style="margin:0 0 16px;">
        Most of the time, we watch alone on a screen with no one around. Or we leave a theater still thinking, still feeling, still wanting to talk about what we just saw and that energy has nowhere to go. The lights come up, people scatter, and whatever was sparked disappears too quickly.
      </p>

      <p style="margin:0 0 16px;">TimeSink is built to hold onto that.</p>

      <p style="margin:0 0 16px;">
        It also provides a stage for filmmakers. Musicians have countless stages to share their work. Cinema deserves more spaces like that too, especially for films that need the right room, the right context, and the right audience.
      </p>

      <p style="margin:0 0 16px;">
        What matters here isn't budget, scale, or access, just whether something is worth experiencing and talking about. That can come from anywhere.
      </p>

      <p style="margin:0 0 16px;">
        Just as importantly, I want TimeSink to grow into a rich community of viewers, creators, programmers, and interesting people from all over the world connecting through cinema, ideas, taste, disagreement, interpretation, and discovery. As Marcel Duchamp said, the viewer completes the work. Film doesn't only live on the screen, but in the response it creates and the conversation it opens.
      </p>

      <p style="margin:0 0 24px;">You're joining early, as everything is beginning to take shape.</p>
      
    <!-- What's here -->
      <p style="margin:0 0 12px;font-family:'Ano Regular Wide',Georgia,serif;font-size:11px;letter-spacing:0.15em;text-transform:uppercase;color:#888888;">
        What you'll find here
      </p>
      <ul style="margin:0 0 24px;padding-left:20px;color:#e8e8e8;">
        <li style="padding:4px 0;">Curated film showcases, each with its own theater room</li>
        <li style="padding:4px 0;">
          Shared screenings that bring people into the same experience together
        </li>
        <li style="padding:4px 0;">A live chat where conversations don't die on the sidewalk</li>
        <li style="padding:4px 0;">
          Audience notes tied to specific moments in a film, appearing as it plays
        </li>
        <li style="padding:4px 0;">
          Director commentary presented the same way, tied directly to the film
        </li>
        <li style="padding:4px 0;">
          A home for filmmakers to present work and for viewers to respond
        </li>
        <li style="padding:4px 0;">An arthouse cinema built for connecting, not scrolling</li>
      </ul>

      <p style="margin:0 0 16px;">
        We've also opened a Substack where we'll publish editorials, film notes, and behind-the-scenes writing around the films and ideas that shape the platform:
        <a href="https://timesinkpresents.substack.com/" style="color:#e8e8e8;">
          timesinkpresents.substack.com
        </a>
      </p>

      <p style="margin:0 0 16px;">
        TimeSink is small right now, intentionally. I'm building it slowly and carefully, with the goal of shaping something distinctive, alive, and lasting.
      </p>

      <p style="margin:0 0 32px;">
        This is just the beginning. As the next showcases and premieres take shape, you'll hear from us.
      </p>

      <p style="margin:0 0 4px;">Thanks for being here early.</p>
      <p style="margin:0 0 24px;">See you in the theater,</p>

      <p style="margin:0 0 4px;color:#e8e8e8;">Aaron</p>
      <p style="margin:0 0 24px;font-size:13px;color:#888888;">Founder, TimeSink</p>

      <p style="margin:0;font-size:13px;color:#555555;">
        P.S. If you ever want to share thoughts, ideas, or just say hi, hit reply. I'll read everything.
      </p>
    </.layout>
    """
  end

  def render_to_html(first_name) do
    assigns = %{first_name: first_name}
    render(assigns) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end

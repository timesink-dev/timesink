defmodule TimesinkWeb.WaitlistConfirmationEmail do
  use Phoenix.Component
  import TimesinkWeb.EmailComponents

  def render(assigns) do
    ~H"""
    <.layout>
      <p style="margin:0 0 24px;font-size:22px;font-weight:normal;color:#e8e8e8;font-family:'Gangster Grotesk',Georgia,serif;letter-spacing:0.05em;">
        You're on the waitlist.
      </p>

      <p style="margin:0 0 16px;">Hi {@first_name},</p>

      <p style="margin:0 0 16px;">
        Thanks for signing up for early access to TimeSink. You're officially on the waitlist.
      </p>

      <p style="margin:0 0 16px;">
        We introduce new members gradually as we shape the community and programming, and we'll email you as soon as your spot opens.
      </p>

      <p style="margin:0 0 16px;">
        In the meantime, you can get a feel for what we're building at our Substack, where we share programming notes, editorials, critiques, and film analysis:
      </p>

      <p style="margin:0 0 32px;">
        <a href="https://timesinkpresents.substack.com/" style="color:#e8e8e8;">
          timesinkpresents.substack.com
        </a>
      </p>

      <p style="margin:0 0 24px;">If you have any questions, just reply to this email.</p>

      <p style="margin:0;color:#888888;font-size:14px;">TimeSink</p>
    </.layout>
    """
  end

  def render_to_html(first_name) do
    assigns = %{first_name: first_name}
    render(assigns) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end

defmodule TimesinkWeb.FilmSubmissionReceivedEmail do
  use Phoenix.Component
  import TimesinkWeb.EmailComponents

  def render(assigns) do
    ~H"""
    <.layout>
      <p style="margin:0 0 24px;font-size:22px;font-weight:normal;color:#e8e8e8;font-family:'Gangster Grotesk',Georgia,serif;letter-spacing:0.05em;">
        We've received your submission.
      </p>

      <p style="margin:0 0 16px;">Hi {@contact_name},</p>

      <p style="margin:0 0 16px;">
        We've received your film submission <em>{@title}</em>. Our team will review it carefully and get back to you soon.
      </p>

      <p style="margin:0 0 32px;">
        You can check the status of your submission anytime from your dashboard:
      </p>

      <table cellpadding="0" cellspacing="0" style="margin-bottom:32px;">
        <tr>
          <td style="background-color:#e8e8e8;border-radius:2px;">
            <a
              href={@dashboard_url}
              style="display:inline-block;padding:14px 28px;font-family:'Gangster Grotesk',Georgia,serif;font-size:14px;letter-spacing:0.08em;color:#0a0a0a;text-decoration:none;font-weight:300;"
            >
              View Submission Status
            </a>
          </td>
        </tr>
      </table>

      <p style="margin:0 0 24px;">
        If you have any questions, feel free to reach out at <a
          href="mailto:hello@timesinkpresents.com"
          style="color:#e8e8e8;"
        >hello@timesinkpresents.com</a>.
      </p>

      <p style="margin:0 0 4px;">Thank you for sharing your work with TimeSink.</p>

      <p style="margin:24px 0 0;color:#888888;font-size:14px;">TimeSink</p>
    </.layout>
    """
  end

  def render_to_html(contact_name, title, dashboard_url) do
    assigns = %{contact_name: contact_name, title: title, dashboard_url: dashboard_url}
    render(assigns) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end

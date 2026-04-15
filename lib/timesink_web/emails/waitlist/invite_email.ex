defmodule TimesinkWeb.InviteEmail do
  use Phoenix.Component
  import TimesinkWeb.EmailComponents

  def render(assigns) do
    ~H"""
    <.layout>
      <p style="margin:0 0 24px;font-size:22px;font-weight:normal;color:#e8e8e8;font-family:'Gangster Grotesk',Georgia,serif;letter-spacing:0.05em;">
        Your invitation to TimeSink
      </p>

      <p style="margin:0 0 16px;">Hi {@first_name},</p>

      <p style="margin:0 0 16px;">
        Great news! Your spot is ready. You're now officially invited to join TimeSink.
      </p>

      <p style="margin:0 0 32px;">
        Click below to create your account and step inside:
      </p>
      
    <!-- CTA -->
      <table cellpadding="0" cellspacing="0" style="margin-bottom:32px;">
        <tr>
          <td style="background-color:#e8e8e8;border-radius:2px;">
            <a
              href={@invite_url}
              style="display:inline-block;padding:14px 28px;font-family:'Gangster Grotesk',Georgia,serif;font-size:14px;letter-spacing:0.08em;color:#0a0a0a;text-decoration:none;font-weight:300;"
            >
              Accept Invitation
            </a>
          </td>
        </tr>
      </table>

      <p style="margin:0 0 8px;font-size:13px;color:#888888;">
        Or copy this link into your browser:
      </p>
      <p style="margin:0 0 24px;font-size:13px;color:#888888;word-break:break-all;">
        {@invite_url}
      </p>

      <p style="margin:0;">We're glad to have you with us.</p>

      <p style="margin:24px 0 0;color:#888888;font-size:14px;">
        TimeSink
      </p>
    </.layout>
    """
  end

  def render_to_html(first_name, invite_url) do
    assigns = %{first_name: first_name, invite_url: invite_url}
    render(assigns) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end

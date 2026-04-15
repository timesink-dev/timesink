defmodule TimesinkWeb.CreativeClaimRejectedEmail do
  use Phoenix.Component
  import TimesinkWeb.EmailComponents

  def render(assigns) do
    ~H"""
    <.layout>
      <p style="margin:0 0 24px;font-size:22px;font-weight:normal;color:#e8e8e8;font-family:'Gangster Grotesk',Georgia,serif;letter-spacing:0.05em;">
        An update on your creative claim.
      </p>

      <p style="margin:0 0 16px;">Hi {@first_name},</p>

      <p style="margin:0 0 16px;">
        Thank you for submitting a claim for the creative profile <em>{@creative_name}</em>.
      </p>

      <p style="margin:0 0 24px;">
        After review, we were unable to verify this claim at this time. If you believe this is a mistake or have additional information to share, please reply to this email.
      </p>

      <p style="margin:0;color:#888888;font-size:14px;">TimeSink</p>
    </.layout>
    """
  end

  def render_to_html(first_name, creative_name) do
    assigns = %{first_name: first_name, creative_name: creative_name}
    render(assigns) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end

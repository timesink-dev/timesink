defmodule TimesinkWeb.CreativeClaimApprovedEmail do
  use Phoenix.Component
  import TimesinkWeb.EmailComponents

  def render(assigns) do
    ~H"""
    <.layout>
      <p style="margin:0 0 24px;font-size:22px;font-weight:normal;color:#e8e8e8;font-family:'Gangster Grotesk',Georgia,serif;letter-spacing:0.05em;">
        Your creative profile has been verified.
      </p>

      <p style="margin:0 0 16px;">Hi {@first_name},</p>

      <p style="margin:0 0 16px;">
        Great news! Your claim for the creative profile <em>{@creative_name}</em> has been approved.
      </p>

      <p style="margin:0 0 24px;">
        Your TimeSink profile now reflects your status as a verified creative. Your name will appear as a link in film credits where your work is listed.
      </p>

      <p style="margin:0 0 4px;">See you in the theater,</p>
      <p style="margin:0;color:#888888;font-size:14px;">TimeSink</p>
    </.layout>
    """
  end

  def render_to_html(first_name, creative_name) do
    assigns = %{first_name: first_name, creative_name: creative_name}
    render(assigns) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end

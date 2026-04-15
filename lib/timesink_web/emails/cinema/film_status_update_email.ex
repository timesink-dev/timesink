defmodule TimesinkWeb.FilmStatusUpdateEmail do
  use Phoenix.Component
  import TimesinkWeb.EmailComponents

  def render(assigns) do
    ~H"""
    <.layout>
      <p style="margin:0 0 24px;font-size:22px;font-weight:normal;color:#e8e8e8;font-family:'Gangster Grotesk',Georgia,serif;letter-spacing:0.05em;">
        {heading(@status)}
      </p>

      <p style="margin:0 0 16px;">Hi {@contact_name},</p>

      <p style="margin:0 0 24px;">{@message}</p>

      <p style="margin:0 0 24px;">
        If you have any questions, you can always reach us at <a
          href="mailto:hello@timesinkpresents.com"
          style="color:#e8e8e8;"
        >hello@timesinkpresents.com</a>.
      </p>

      <p style="margin:0;color:#888888;font-size:14px;">TimeSink</p>
    </.layout>
    """
  end

  defp heading(:accepted), do: "Your film has been accepted."
  defp heading(:rejected), do: "An update on your submission."
  defp heading(:under_review), do: "Your film is under review."
  defp heading(_), do: "An update on your submission."

  def render_to_html(contact_name, message, status) do
    assigns = %{contact_name: contact_name, message: message, status: status}
    render(assigns) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end

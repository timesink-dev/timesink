defmodule TimesinkWeb.StripeController do
  use TimesinkWeb, :controller

  alias TimesinkWeb.StripeWebhookHandler

  def webhook(conn, %{"type" => _type} = params) do
    StripeWebhookHandler.handle_event(params)
    send_resp(conn, :no_content, "")
  end
end

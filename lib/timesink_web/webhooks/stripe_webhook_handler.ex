defmodule TimesinkWeb.StripeWebhookHandler do
  def handle_event(%{"type" => "payment_intent.created"} = event) do
    IO.inspect(event, label: "🟡 PAYMENT INTENT CREATED")
    :ok
  end

  def handle_event(%{"type" => "checkout.session.completed"} = event) do
    IO.inspect(event, label: "✅ CHECKOUT SESSION COMPLETED")
    :ok
  end

  def handle_event(%{"type" => "invoice.paid"} = event) do
    IO.inspect(event, label: "💰 INVOICE PAID")
    :ok
  end

  def handle_event(event) do
    IO.inspect(event, label: "⚠️ UNKNOWN EVENT TYPE")
    :ok
  end
end

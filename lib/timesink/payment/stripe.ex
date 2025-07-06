defmodule Timesink.Payment.Stripe do
  alias Stripe.PaymentIntent

  @doc """
  Creates a Stripe PaymentIntent with a specified amount (in cents) and currency.
  You can also attach metadata for later reference (e.g. film title, user ID).
  """
  def create_payment_intent(%{amount: amount, currency: currency, metadata: metadata}) do
    PaymentIntent.create(%{
      amount: amount,
      currency: currency,
      metadata: metadata,
      automatic_payment_methods: %{enabled: true}
    })
  end

  def config do
    Application.get_env(:timesink, :stripe) |> Enum.into(%{})
  end
end

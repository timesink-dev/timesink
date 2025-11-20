defmodule Timesink.Payment.BtcPay do
  @moduledoc """
  The `Timesink.Payment.BtcPay` module provides an interface for interacting with BTCPay Server
  to handle Bitcoin payments for film submissions.

  It supports:

  - Creating invoices for film submission fees
  - Handling webhook notifications for payment status updates

  ## Features

  - Create and manage invoices using BTCPay Server API
  - Process payment notifications via webhooks

  ## Example Usage

      iex> Timesink.Payment.BtcPay.create_invoice(%{amount: 1000, currency: "USD"})
      {:ok, %{"id" => "invoice123", ...}}

      iex> Timesink.Payment.BtcPay.handle_webhook(conn, params)
      {:ok, "Invoice processed"}

  """

  def create_invoice(%{amount: amount, currency: currency, metadata: metadata}) do
    config = btc_pay_config()

    url = "#{config.url}/api/v1/stores/#{config.store_id}/invoices"

    body =
      %{
        amount: amount,
        currency: currency,
        metadata: metadata,
        notificationURL: config.webhook_url
      }
      |> Jason.encode!()

    headers = [
      {"Authorization", "token #{config.api_key}"},
      {"Content-Type", "application/json"}
    ]

    req = Finch.build(:post, url, headers, body)

    case http_client().request(req) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        Jason.decode(body)

      {:ok, %Finch.Response{status: code, body: body}} ->
        {:error, {:http_error, code, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp btc_pay_config, do: Application.fetch_env!(:timesink, :btc_pay) |> Enum.into(%{})

  defp http_client do
    Application.get_env(:timesink, :http_client, Finch)
  end
end

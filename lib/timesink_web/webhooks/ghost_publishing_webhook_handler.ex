defmodule TimesinkWeb.GhostPublishingWebhookHandler do
  def handle_event(%{"type" => "post.published", "data" => %{"post" => %{"current" => post}}}) do
    inspect(post, label: "Ghost Post Published")
    # Here you would typically process the post data, e.g., save it to your database
    :ok
  end

  def handle_event(%{"type" => "post.updated", data: data}) do
    inspect(data, label: "Ghost Post Updated")
    # Handle pot updates similarly
    :ok
  end

  # fallback for unhandled events
  def handle_event(%{"type" => type}) do
    IO.inspect(type, label: "Unhandled Ghost Publishing Event")
  end
end

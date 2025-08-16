defmodule TimesinkWeb.GhostPublishingWebhookHandler do
  alias Timesink.BlogPost

  def handle_event(%{"type" => "post.published", "data" => %{"post" => %{"current" => post}}}) do
    IO.inspect(post, label: "Ghost Post Published")

    with {:ok, _blog_post} <-
           BlogPost.create(%{
             title: post["title"],
             slug: post["slug"],
             content: post["html"] || post["plaintext"] || "",
             author: get_in(post, ["primary_author", "name"]) || "Unknown",
             published_at: parse_datetime(post["published_at"])
           }) do
      :ok
    else
      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "BlogPost Creation Error")
        :error
    end
  end

  def handle_event(%{"type" => "post.updated", "data" => %{"post" => %{"current" => post}}}) do
    IO.inspect(post, label: "Ghost Post Updated")

    with {:ok, %BlogPost{} = existing} <- BlogPost.get_by(slug: post["slug"]),
         {:ok, _updated} <-
           BlogPost.update(existing, %{
             title: post["title"],
             slug: post["slug"],
             content: post["html"] || post["plaintext"] || "",
             author: get_in(post, ["primary_author", "name"]) || "Unknown",
             published_at: parse_datetime(post["published_at"])
           }) do
      :ok
    else
      {:error, :not_found} ->
        IO.warn("No BlogPost found with ghost_uuid=#{post["uuid"]}")
        :error

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "BlogPost Update Error")
        :error
    end
  end

  def handle_event(%{"type" => "post.deleted", "data" => %{"post" => %{"previous" => post}}}) do
    IO.inspect(post, label: "Ghost Post Deleted")

    with {:ok, %BlogPost{} = existing} <- BlogPost.get_by(slug: post["slug"]),
         {:ok, _deleted} <- BlogPost.delete(existing) do
      :ok
    else
      {:error, :not_found} ->
        IO.warn("No BlogPost found to delete with slug=#{post["slug"]}")
        :error

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "BlogPost Deletion Error")
        :error
    end
  end

  def handle_event(%{"type" => type}) do
    IO.inspect(type, label: "Unhandled Ghost Publishing Event")
    :ok
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
end

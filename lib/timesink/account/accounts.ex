defmodule Timesink.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Timesink.Accounts.User
  alias Timesink.Accounts.Mail
  import Ecto.Query
  alias Timesink.Token

  @code_expiration_minutes 15

  @doc """
  Query users through a function hook using the [Ecto.Query API](https://hexdocs.pm/ecto/Ecto.Query.html).

  ## Examples

  Get three random active users with:

      iex> Accounts.query_users(fn query ->
        query
        |> where([u], u.is_active == true)
        |> limit(3)
      end)
      {:ok, [%User{...}, %User{...}, %User{...}]}

  Get the most recent active user with:

      iex> Accounts.query_users(fn query ->
        query
        |> where([u], u.is_active == true)
        |> order_by([u], [asc: u.inserted_at])
        |> limit(1)
      end)
      {:ok, [%User{...}]}
  """
  @spec query_users(filter :: (Ecto.Query.t() -> Ecto.Query.t())) ::
          {:ok, list(User.t())} | {:error, term()}
  def query_users(f) do
    with {:ok, users} <- User.query(f) do
      {:ok, users}
    end
  end

  @doc """
  Retrieves the current user and their associated profile information.
  """
  def get_me(user_id) do
    user_id = to_string(user_id)
    user = User.get!(user_id) |> Timesink.Repo.preload(:profile)

    {:ok, user}
  end

  def send_email_verification(email) do
    # Generate a 6-digit random code
    code = :rand.uniform(999_999) |> Integer.to_string() |> String.pad_leading(6, "0")

    expires_at = DateTime.add(DateTime.utc_now(), @code_expiration_minutes * 60, :second)

    # token_changeset =
    #   Token.changeset(%Token{}, %{
    #     kind: :email_verification,
    #     secret: code,
    #     expires_at: expires_at
    #   })

    with {:ok, _token} <-
           Token.create(%{
             kind: :email_verification,
             secret: code,
             expires_at: expires_at
           }) do
      Mail.send_email_verification(email, code)
      {:ok, :sent}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec verify_email(any()) :: {:error, :invalid_or_expired} | {:ok, :verified}
  def verify_email(entered_code) do
    query =
      from t in Token,
        where:
          t.kind == :email_verification and
            t.secret == ^entered_code and
            t.status == :active and
            t.expires_at > ^DateTime.utc_now(),
        select: t

    with {:ok, token} <- Token.get(query) do
      Token.update(token, %{
        status: :used
      })

      {:ok, :verified}
    else
      _ -> {:error, :invalid_or_expired}
    end
  end

  def verify_password_conformity(password, password_confirmation) do
    # Check if the password and password_confirmation match and conform to the password policy TBD
    if password == password_confirmation do
      {:ok, :matched}
    else
      {:error, :mismatch}
    end
  end
end

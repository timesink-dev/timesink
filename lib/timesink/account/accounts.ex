defmodule Timesink.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Timesink.Accounts.User
  alias Timesink.Accounts.Mail
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

  def send_email_verification(email) when is_binary(email) do
    IO.inspect(email, label: "Toot Email")
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
             expires_at: expires_at,
             email: email
           }) do
      Mail.send_email_verification(email, code)
      {:ok, :sent}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  # def validate_email_verification_code(code, user_id) do
  #   # Check if the code exists in the database and is associated with the current user's email and hasn't expired
  #   with {:ok, token} <-
  #          Token.get_by(%{
  #            secret: code,
  #            kind: :email_verification,
  #            status: :active,
  #            #  expires_at: DateTime.utc_now(),
  #            user_id: user_id
  #          }) do
  #     # invalidate the token
  #     Token.update(token, %{
  #       status: :used
  #     })

  #     {:ok, token}
  #   else
  #     _ -> {:error, :invalid_or_expired}
  #   end
  # end

  def validate_email_verification_code(code, email) do
    with {:ok, token} <-
           Token.get_by(%{
             secret: code,
             kind: :email_verification,
             status: :valid,
             email: email
             # expires_at: DateTime.utc_now()
           }) do
      # invalidate the token
      Token.update(token, %{
        status: :invalid
      })

      {:ok, token}
    else
      _ -> {:error, :invalid_or_expired}
    end
  end

  def verify_password_conformity(password, password_confirmation) do
    if password == password_confirmation do
      {:ok, :matched}
    else
      {:error, :password_mismatch}
    end
  end

  @doc """
  Creates a new user with the given parameters.
  For now this is called at the end of the onboarding process.
  """
  def create_user(params) do
    password = params["password"]
    hashed_password = Argon2.hash_pwd_salt(password)
    params = Map.put(params, "password", hashed_password)

    with {:ok, user} <- User.create(params) do
      {:ok, user}
    else
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def is_username_available?(username) do
    with {:ok, _user} <- User.get_by(username: username) do
      {:error, :username_taken}
    else
      {:error, :not_found} -> {:ok, :available}
      {:error, _} -> {:error, :unknown}
    end
  end

  def is_email_available?(email) do
    with {:ok, _user} <- User.get_by(email: email) do
      {:error, :email_taken}
    else
      {:error, :not_found} -> {:ok, :available}
      {:error, _} -> {:error, :unknown}
    end
  end
end

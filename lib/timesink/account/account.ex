defmodule Timesink.Account do
  @moduledoc """
  The Account context.
  """

  alias Timesink.Account.User
  alias Timesink.Account.Mail
  alias Timesink.Token
  alias TimesinkWeb.Utils

  # email verification codes
  @code_expiration_minutes 15
  # password reset tokens (link valid for 60 minutes)
  @reset_expiration_minutes 60

  @doc """
  Query users through a function hook using the [Ecto.Query API](https://hexdocs.pm/ecto/Ecto.Query.html).
  """
  @spec query_users(filter :: (Ecto.Query.t() -> Ecto.Query.t())) ::
          {:ok, list(User.t())} | {:error, term()}
  def query_users(f) do
    with {:ok, users} <- User.query(f) do
      {:ok, users}
    end
  end

  @spec get_me(any()) ::
          {:ok, nil | [%{optional(atom()) => any()}] | %{optional(atom()) => any()}}
  @doc """
  Retrieves the current user and their associated profile information.
  """
  def get_me(user_id) do
    user_id = to_string(user_id)
    user = User.get!(user_id) |> Timesink.Repo.preload(:profile)
    {:ok, user}
  end

  def send_email_verification(email) when is_binary(email) do
    # Generate a 6-digit random code
    code = :rand.uniform(999_999) |> Integer.to_string() |> String.pad_leading(6, "0")
    expires_at = DateTime.add(DateTime.utc_now(), @code_expiration_minutes * 60, :second)

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

  def validate_email_verification_code(code, email) do
    with {:ok, token} <-
           Token.get_by(%{
             secret: code,
             kind: :email_verification,
             status: :valid,
             email: email
           }),
         false <- Token.is_expired?(token) do
      Token.invalidate_token(token)
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

  # ----------------------------------------
  # NEW: Password reset (email link flow)
  # ----------------------------------------

  @doc """
  Sends a password reset email with a time-limited tokenized link.

  Always returns :ok to avoid user enumeration.
  """
  @spec deliver_user_reset_password_instructions(String.t(), (binary() -> String.t())) :: :ok
  def deliver_user_reset_password_instructions(email, url_fun)
      when is_binary(email) and is_function(url_fun, 1) do
    # Normalize email and look up user; we keep response neutral regardless of presence
    email = email |> String.trim() |> String.downcase()

    with {:ok, user} <- User.get_by(email: email) do
      token = random_url_token()
      expires_at = DateTime.add(DateTime.utc_now(), @reset_expiration_minutes * 60, :second)

      # Store a token row we can validate later. We reuse your Token module API.
      # We store the email so we can fetch the User later without Repo.
      :ok =
        case Token.create(%{
               kind: :password_reset,
               secret: token,
               expires_at: expires_at,
               status: :valid,
               email: user.email
             }) do
          {:ok, _} -> :ok
          {:error, _} -> :ok
        end

      # Send the email (implement Mail.send_password_reset/2 if not already present)
      Mail.send_password_reset(user.email, url_fun.(token))
    else
      _ -> :ok
    end

    :ok
  end

  @doc """
  Validates a password reset token and returns the user if valid; otherwise returns nil.

  Use this to decide whether to show the "set new password" form.
  """
  @spec get_user_by_reset_password_token(binary()) :: User.t() | nil
  def get_user_by_reset_password_token(token) when is_binary(token) do
    with {:ok, t} <-
           Token.get_by(%{
             secret: token,
             kind: :password_reset,
             status: :valid
           }),
         false <- Token.is_expired?(t),
         {:ok, user} <- User.get_by(email: t.email) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Consumes a valid reset (user already verified from token page) and updates the password.

  Expects attrs like: %{"password" => "...", "password_confirmation" => "..."}.
  Hashes with Argon2 and updates the `:password` column (your schema stores the hash there).
  """
  @spec reset_user_password(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def reset_user_password(%User{} = user, attrs) when is_map(attrs) do
    case validate_new_password(attrs) do
      {:ok, plain} ->
        hashed = Argon2.hash_pwd_salt(plain)

        case User.update(
               user,
               %{"email" => user.email, "password" => hashed},
               changeset: &User.email_password_changeset/2
             ) do
          {:ok, updated} ->
            invalidate_all_password_resets_for_email(updated.email)
            {:ok, updated}

          {:error, cs} ->
            {:error, cs}
        end

      {:error, cs} ->
        {:error, cs}
    end
  end

  # ----------------------------------------
  # NEW: In-session password change
  # ----------------------------------------

  @doc """
  Returns a changeset-like struct for validating password inputs on the client.

  We use a map-based changeset so you don't need virtual fields on the schema.
  """
  @spec change_user_password(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_password(_user, attrs \\ %{}) do
    password_validation_changeset(attrs) |> Map.put(:action, :validate)
  end

  @doc """
  Verifies current_password and, if valid, updates to the new password.

  `attrs` should include "password" and "password_confirmation".
  """
  @spec update_user_password(User.t(), String.t(), map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user_password(%User{} = user, current_password, attrs)
      when is_binary(current_password) and is_map(attrs) do
    # 1) verify current password
    case User.valid_password?(user, current_password) do
      {:ok, _} ->
        # 2) validate new password (presence/length/confirmation)
        case validate_new_password(attrs) do
          {:ok, plain} ->
            hashed = Argon2.hash_pwd_salt(plain)

            # 3) update using a password-only changeset
            case User.update(user, %{"password" => hashed},
                   changeset: &User.password_only_changeset/2
                 ) do
              {:ok, updated} -> {:ok, updated}
              {:error, cs} -> {:error, cs}
            end

          {:error, cs} ->
            {:error, cs}
        end

      # any non-{:ok, _} means invalid current password
      _ ->
        cs =
          password_validation_changeset(attrs)
          |> Ecto.Changeset.add_error(
            :current_password,
            "Password entered does not match your current password"
          )

        {:error, cs}
    end
  end

  # ----------------------------------------
  # Internals (private helpers)
  # ----------------------------------------

  # Validate presence, length >= 8, and confirmation.
  # Returns {:ok, plain_password} or {:error, changeset}.
  defp validate_new_password(attrs) do
    cs = password_validation_changeset(attrs)

    case Ecto.Changeset.apply_action(cs, :insert) do
      {:ok, %{password: plain}} -> {:ok, plain}
      {:error, cs} -> {:error, cs}
    end
  end

  defp password_validation_changeset(attrs) do
    types = %{password: :string, password_confirmation: :string, current_password: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(attrs, Map.keys(types))
    |> Utils.trim_fields([:password, :password_confirmation, :current_password])
    |> Ecto.Changeset.validate_required([:password, :password_confirmation])
    |> Ecto.Changeset.validate_length(:password,
      min: 8,
      message: "Password must be at least 8 characters"
    )
    |> Ecto.Changeset.validate_confirmation(:password,
      message: "The password you have entered does not match"
    )
  end

  defp random_url_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp invalidate_all_password_resets_for_email(email) do
    # If we don't have a bulk invalidate function, we can fetch and invalidate the latest; otherwise, we
    # can create a helper in Token to invalidate all by kind+email.
    with {:ok, token} <-
           Token.get_by(%{
             kind: :password_reset,
             status: :valid,
             email: email
           }) do
      # Best-effort; if there are multiple, invalidate one-by-one or extend our Token module.
      Token.invalidate_token(token)
    else
      _ -> :ok
    end
  end

  # ----------------------------------------
  # Email Change Verification
  # ----------------------------------------

  @doc """
  Initiates email change process by storing new email in unverified_email
  and sending a verification link.

  Takes a URL function that will generate the verification link URL from the token.

  Returns {:ok, user} if successful, {:error, reason} otherwise.
  """
  @spec initiate_email_change(User.t(), String.t(), (binary() -> String.t())) ::
          {:ok, User.t()} | {:error, term()}
  def initiate_email_change(%User{} = user, new_email, url_fun)
      when is_binary(new_email) and is_function(url_fun, 1) do
    new_email = String.trim(new_email) |> String.downcase()

    # Check if email is already taken
    case is_email_available?(new_email) do
      {:ok, :available} ->
        # Update unverified_email field
        case User.update(user, %{"unverified_email" => new_email}) do
          {:ok, updated_user} ->
            # Generate and send verification link
            case send_email_change_verification(updated_user, url_fun) do
              {:ok, :sent} -> {:ok, updated_user}
              {:error, reason} -> {:error, reason}
            end

          {:error, changeset} ->
            {:error, changeset}
        end

      {:error, :email_taken} ->
        {:error, :email_already_in_use}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Sends an email with a one-click verification link to the user's current email address.
  # The token stores the unverified_email so it can be moved to email upon verification.
  @spec send_email_change_verification(User.t(), (binary() -> String.t())) ::
          {:ok, :sent} | {:error, term()}
  defp send_email_change_verification(%User{} = user, url_fun)
       when is_function(url_fun, 1) do
    # Generate a URL-safe token
    token = random_url_token()
    expires_at = DateTime.add(DateTime.utc_now(), @code_expiration_minutes * 60, :second)

    with {:ok, _token} <-
           Token.create(%{
             kind: :email_verification,
             secret: token,
             expires_at: expires_at,
             # Store the unverified_email (new email) in the token so we can update to it later
             email: user.unverified_email,
             user_id: user.id
           }) do
      # Generate the verification URL using the provided function
      url = url_fun.(token)
      # Send to the current (old) email for security verification
      Mail.send_email_change_verification(user.email, url)
      {:ok, :sent}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Verifies the email change token from the email link and updates the user's email.

  On success:
  - Moves unverified_email to email
  - Clears unverified_email
  - Invalidates the token

  Returns {:ok, user} or {:error, reason}
  """
  @spec verify_email_change_token(String.t()) ::
          {:ok, User.t()} | {:error, :invalid_or_expired | :no_pending_email}
  def verify_email_change_token(token) when is_binary(token) do
    with {:ok, token_record} <-
           Token.get_by(%{
             secret: token,
             kind: :email_verification,
             status: :valid
           }),
         false <- Token.is_expired?(token_record),
         {:ok, user} <- User.get(token_record.user_id) do
      case User.update(user, %{"email" => token_record.email, "unverified_email" => nil},
             changeset: &User.email_only_changeset/2
           ) do
        {:ok, updated_user} ->
          Token.invalidate_token(token_record)
          {:ok, updated_user}

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      {:error, :not_found} -> {:error, :invalid_or_expired}
      true -> {:error, :invalid_or_expired}
      _ -> {:error, :invalid_or_expired}
    end
  end

  @doc """
  Cancels a pending email change by clearing the unverified_email field
  and invalidating any related tokens.
  """
  @spec cancel_email_change(User.t()) :: {:ok, User.t()} | {:error, term()}
  def cancel_email_change(%User{unverified_email: nil} = user), do: {:ok, user}

  def cancel_email_change(%User{unverified_email: email} = user) when is_binary(email) do
    # Invalidate any pending tokens
    with {:ok, token} <-
           Token.get_by(%{
             kind: :email_verification,
             status: :valid,
             email: email,
             user_id: user.id
           }) do
      Token.invalidate_token(token)
    else
      _ -> :ok
    end

    # Clear unverified_email
    User.update(user, %{"unverified_email" => nil})
  end
end

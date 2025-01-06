defmodule Timesink.Token do
  use Ecto.Schema
  import Ecto.Query
  alias Timesink.Token

  @hash_algorithm :sha256
  @rand_size 32

  # Token validity periods
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @change_email_validity_in_days 7
  @session_validity_in_days 60
  @onboarding_invite_validity_in_days 14

  @primary_key {:id, :binary_id, autogenerate: true}

  @token_types [:session, :password_reset, :onboarding_invite]

  schema "token" do
    field :token, :binary
    field :type, Ecto.Enum, values: @token_types
    field :sent_to, :string
    belongs_to :user, Timesink.Accounts.User
    belongs_to :applicant, Timesink.Waitlist.Applicant

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Builds a session token for a user.
  """
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %Token{token: token, type: "session", user_id: user.id}}
  end

  @doc """
  Builds an email token for account-related actions.
  """
  def build_email_token(user, type) do
    build_hashed_token(user, type, user.email)
  end

  @doc """
  Builds an onboarding invite token for an applicant.
  """
  def build_onboarding_invite_token(applicant) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %Token{
       token: hashed_token,
       type: "onboarding_invite",
       applicant_id: applicant.id,
       sent_to: applicant.email
     }}
  end

  @doc """
  Verifies a session token.
  """
  def verify_session_token_query(token) do
    query =
      from token in by_token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user

    {:ok, query}
  end

  @doc """
  Verifies an email token for various contexts.
  """
  def verify_email_token_query(token, type) do
    decode_and_verify_token(token, type, fn decoded_token, days ->
      from token in by_token_and_context_query(decoded_token, type),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(^days, "day") and token.sent_to == user.email,
        select: user
    end)
  end

  @doc """
  Verifies an onboarding invite token.
  """
  def verify_onboarding_invite_token_query(token) do
    decode_and_verify_token(token, "onboarding_invite", fn decoded_token, days ->
      from token in by_token_and_context_query(decoded_token, "onboarding_invite"),
        join: applicant in assoc(token, :applicant),
        where: token.inserted_at > ago(^days, "day"),
        select: applicant
    end)
  end

  defp build_hashed_token(user, type, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %Token{
       token: hashed_token,
       type: type,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  defp decode_and_verify_token(token, type, query_fun) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(type)
        {:ok, query_fun.(hashed_token, days)}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days
  defp days_for_context("onboarding_invite"), do: @onboarding_invite_validity_in_days

  @doc """
  Returns the token struct for the given token value and type.
  """
  def by_token_and_context_query(token, type) do
    from Token, where: [token: ^token, type: ^type]
  end
end

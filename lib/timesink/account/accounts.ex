defmodule Timesink.Accounts do
  alias Timesink.Accounts.Profile
  alias Timesink.Accounts.User

  @moduledoc """
  The Accounts context.
  """

  # Mock implementation for development
  @mock_current_user_id ~c"5ca3328d-2e94-4bec-80a4-90595bc98d5b"

  def get_user_by!(fields), do: User.get_by(fields)

  @doc """
  Retrieves the current user and their associated profile information.
  """
  def get_me(user_id \\ @mock_current_user_id) do
    user_id = to_string(user_id)

    user = User.get!(user_id)

    case user do
      nil ->
        {:error, "User not found"}

      user ->
        profile = Profile.get_by!(user_id: user.id)

        {:ok, %{user: user, profile: profile}}
    end
  end
end

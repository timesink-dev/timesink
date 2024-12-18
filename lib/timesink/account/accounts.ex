defmodule Timesink.Accounts do
  alias Timesink.Accounts.Profile
  alias Timesink.Accounts.User
  alias Timesink.Repo

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

    user = User.get!(user_id) |> Timesink.Repo.preload(:profile)

    {:ok, user}
  end

  def update_me(user_id, params) do
    with {:ok, user} <- get_me(user_id) do
      Repo.transaction(fn ->
        Profile.update!(user.profile, params)
        User.update!(user, params)
      end)

      # Fetch the updated user from the database to ensure changes are reflected
      get_me(user_id)
    end
  end
end

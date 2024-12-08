defmodule Timesink.Accounts do
  alias Timesink.Accounts.User
  alias Timesink.Accounts.Profile

  @moduledoc """
  The Accounts context.
  """

  def get_user_by!(fields), do: User.get_by(fields)

  def get_profile_by_username!(username) do
    {:ok, user} = get_user_by!(username)
    profile = Profile.get_by!(user_id: user.id)
    {:ok, %{user: user, profile: profile}}
  end
end

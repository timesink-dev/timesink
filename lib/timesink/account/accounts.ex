defmodule Timesink.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Timesink.Accounts.User
  alias Timesink.Accounts.Profile

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

  def get_user_by!(fields), do: User.get_by(fields)

  def get_profile_by_username!(username) do
    {:ok, user} = get_user_by!(username)
    profile = Profile.get_by!(user_id: user.id)
    {:ok, %{user: user, profile: profile}}
  end
end

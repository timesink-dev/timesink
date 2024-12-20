defmodule Timesink.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Timesink.Accounts.User

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

  def update_me(user, params) do
    user
    |> User.changeset_update(params)
    |> Timesink.Repo.update()
  end
end

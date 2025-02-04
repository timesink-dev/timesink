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
  # TEMP: enter the user id you want to mock from your dev database
  @mock_current_user_id ~c"3416d239-4c5b-414f-a838-2943d2898184"

  @doc """
  Retrieves the current user and their associated profile information.
  """
  def get_me(user_id \\ @mock_current_user_id) do
    user_id = to_string(user_id)
    user = User.get!(user_id) |> Timesink.Repo.preload(:profile)

    {:ok, user}
  end
end

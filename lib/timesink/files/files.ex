defmodule Timesink.Files do
  @moduledoc """
  The Files context.
  """

  alias Timesink.File

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
  @spec query_files(filter :: (Ecto.Query.t() -> Ecto.Query.t())) ::
          {:ok, list(File.t())} | {:error, term()}
  def query_files(f) do
    with {:ok, files} <- File.query(f) do
      {:ok, files}
    end
  end

  def create_file(params, _opts \\ []) do
    Timesink.Repo.transaction(fn ->
      nil
    end)
  end
end

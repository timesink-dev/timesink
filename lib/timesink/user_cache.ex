defmodule Timesink.UserCache do
  use GenServer
  alias Timesink.Repo
  alias Timesink.Account.{User, Profile}
  alias Timesink.Storage.Attachment
  import Ecto.Query

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_or_load(user_id) do
    case :ets.lookup(__MODULE__, user_id) do
      [{^user_id, user}] ->
        {:ok, user}

      [] ->
        with user <- load_user(user_id),
             true <- not is_nil(user) do
          put(user)
          {:ok, user}
        else
          _ -> {:error, :not_found}
        end
    end
  end

  def put(%{id: id} = user) do
    :ets.insert(__MODULE__, {id, user})
    :ok
  end

  def bust(user_id) do
    :ets.delete(__MODULE__, user_id)
    :ok
  end

  # Callbacks

  @impl true
  def init(_) do
    :ets.new(__MODULE__, [:named_table, :public, read_concurrency: true])
    {:ok, %{}}
  end

  # Internal loader (cheap minimal query)
  defp load_user(user_id) do
    Repo.one(
      from u in User,
        where: u.id == ^user_id,
        left_join: p in assoc(u, :profile),
        left_join: a in assoc(p, :avatar),
        left_join: b in assoc(a, :blob),
        select: %{
          id: u.id,
          username: u.username,
          first_name: u.first_name,
          last_name: u.last_name,
          avatar_meta: a.metadata,
          blob_uri: b.uri
        }
    )
    |> case do
      nil ->
        nil

      row ->
        avatar_url =
          case row do
            %{avatar_meta: meta, blob_uri: uri} when is_map(meta) and is_binary(uri) ->
              att = %Attachment{metadata: meta, blob: %{uri: uri}}
              Profile.avatar_url(att, :md)

            _ ->
              Profile.avatar_url(nil)
          end

        %{
          id: row.id,
          username: row.username,
          first_name: row.first_name,
          last_name: row.last_name,
          avatar_url: avatar_url
        }
    end
  end

  def get_avatar_url(user_id) do
    case :ets.lookup(__MODULE__, {:avatar_url, user_id}) do
      [{{:avatar_url, ^user_id}, url}] -> url
      _ -> nil
    end
  end

  def put_avatar_url(user_id, url) do
    true = :ets.insert(__MODULE__, {{:avatar_url, user_id}, url})
    :ok
  end
end

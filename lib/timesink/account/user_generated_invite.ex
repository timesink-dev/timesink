defmodule Timesink.UserGeneratedInvite do
  # 👈 add this
  import Ecto.Query, only: [from: 2]

  alias Timesink.Repo
  alias Timesink.Token

  @base_url Application.compile_env(:timesink, :base_url)

  # Each user gets 2 invites
  @max_invites 2

  def generate_invite(user_id) do
    active_invites =
      Repo.aggregate(
        from(t in Token, where: t.user_id == ^user_id and t.kind == :invite),
        :count,
        :id
      )

    if active_invites < @max_invites do
      token = Ecto.UUID.generate()
      Repo.insert!(%Token{kind: :invite, secret: token, status: :valid, user_id: user_id})
      {:ok, "#{@base_url}/invite/#{token}"}
    else
      {:error, "You've used all your invite tickets!"}
    end
  end
end

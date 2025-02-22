defmodule TimesinkWeb.Plugs.RequireAdmin do
  import Plug.Conn
  import Phoenix.Controller
  import TimesinkWeb.Plugs.Helpers
  import Phoenix.Controller
  use TimesinkWeb, :verified_routes

  def init(default), do: default

  def call(conn, _opts) do
    user = get_user_from_session(conn)

    if !user do
      conn
      |> maybe_store_return_to()
      |> redirect(to: ~p"/sign_in")
      |> halt()
    end

    if isAdmin?(user) do
      # set current user in conn - maybe we want to add some profile editing capabilities sometime later
      assign(conn, :current_user, user)
    else
      conn
      |> put_flash(:error, "Hey there! Access to the backroom is for admins only")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  @spec isAdmin?(User) :: boolean()
  defp isAdmin?(user) do
    if Enum.member?(user.roles, :admin) do
      true
    else
      false
    end
  end
end

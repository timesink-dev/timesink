# defmodule TimesinkWeb.Plugs.AuthenticateAdmin do
#   import Plug.Conn
#   alias Phoenix.Token
#   alias Timesink.Accounts

#   def init(opts), do: opts

#   def call(conn, _opts) do
#     case fetch_cookies(conn, :signed) do
#       nil ->
#         conn
#         |> redirect_to_login()
#         |> halt()

#       token ->
#         case Token.verify(MyAppWeb.Endpoint, "user_auth", token, max_age: 7 * 24 * 60 * 60) do
#           {:ok, claims} ->
#             user = Accounts.get_user!(claims["user_id"])

#             if user.role == "admin" do
#               assign(conn, :current_user, user)
#             else
#               conn
#               |> redirect_to_forbidden()
#               |> halt()
#             end

#           {:error, _reason} ->
#             conn
#             |> redirect_to_login()
#             |> halt()
#         end
#     end
#   end

#   defp redirect_to_login(conn) do
#     conn
#     |> put_flash(:error, "You must be logged in to access this page.")
#     |> redirect(to: "/login")
#   end

#   defp redirect_to_forbidden(conn) do
#     conn
#     |> put_flash(:error, "You do not have permission to access this page.")
#     |> redirect(to: "/forbidden")
#   end
# end

defmodule TimesinkWeb.PageControllerTest do
  use TimesinkWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome to the show."
  end
end

defmodule TimesinkWeb.PageControllerTest do
  use TimesinkWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    IO.inspect(html_response(conn, 200), label: "hello")
    assert html_response(conn, 200) =~ "TimeSink Presents"
  end
end

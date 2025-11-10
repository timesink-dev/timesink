defmodule TimesinkWeb.ErrorHTMLTest do
  use TimesinkWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    html = render_to_string(TimesinkWeb.ErrorHTML, "404", "html", [])
    assert html =~ "Error 404"
    assert html =~ "Uh oh, the Projector Broke"
  end

  test "renders 500.html" do
    html = render_to_string(TimesinkWeb.ErrorHTML, "500", "html", [])
    assert html =~ "Error 500"
    assert html =~ "Technical Difficulties"
  end
end

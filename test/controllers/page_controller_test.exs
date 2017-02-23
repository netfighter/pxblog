defmodule Pxblog.PageControllerTest do
  use Pxblog.ConnCase

  test "GET /page", %{conn: conn} do
    conn = get conn, "/page"
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end

defmodule PxblogWeb.Helpers.ViewHelpersTest do
  use PxblogWeb.ConnCase, async: true
  alias PxblogWeb.Helpers.ViewHelpers
  import Pxblog.Factory

   setup do
    role = insert(:role, name: "User", admin: false)
    user = insert(:user, role: role)
    {:ok, conn: build_conn(), user: user, role: role}
  end

  test "current user returns the user in the session", %{conn: conn, user: user} do
    conn = post conn, session_path(conn, :create), user: %{email: user.email, password: user.password}
    assert ViewHelpers.current_user(conn)
  end

  test "current user returns nothing if there is no user in the session", %{conn: conn, user: user} do
    conn = delete conn, session_path(conn, :delete, user)
    refute ViewHelpers.current_user(conn)
  end

  test "format_date resturns a string with the date formatted with %Y-%m-%d %H:%M" do
    {:ok, dt} = NaiveDateTime.new(2016, 3, 1, 04, 05, 0)
    assert ViewHelpers.format_date(dt) == "2016-03-01 04:05"
  end
end

defmodule Pxblog.ViewHelpersTest do
  use Pxblog.ConnCase, async: true
  alias Pxblog.ViewHelpers
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

  test "allowed_to_delete_comment? allows comment delete if user the author of comment", %{conn: conn, user: user} do
    comment = insert(:comment, user: user)
    conn = post conn, session_path(conn, :create), user: %{email: user.email, password: user.password}
    assert ViewHelpers.allowed_to_delete_comment?(conn, comment)
  end

  test "allowed_to_delete_comment? allows comment delete if user admin", %{conn: conn, user: user} do
    comment = insert(:comment, user: user)
    admin_role = insert(:role, admin: true)
    admin = insert(:user, role: admin_role)
    conn = post conn, session_path(conn, :create), user: %{email: admin.email, password: admin.password}
    assert ViewHelpers.allowed_to_delete_comment?(conn, comment)
  end

  test "allowed_to_delete_comment? forbids comment delete if user is not admin or author of the comment", %{conn: conn, user: user, role: role} do
    comment = insert(:comment, user: user)
    other_user = insert(:user, role: role)
    conn = post conn, session_path(conn, :create), user: %{email: other_user.email, password: other_user.password}
    refute ViewHelpers.allowed_to_delete_comment?(conn, comment)
  end

  test "format_date resturns a string with the date formatted with %Y-%m-%d %H:%M" do
    {:ok, dt} = NaiveDateTime.new(2016, 3, 1, 04, 05, 0)
    assert ViewHelpers.format_date(dt) == "2016-03-01 04:05"
  end
end

defmodule Pxblog.SessionControllerTest do
  use Pxblog.ConnCase
  import Pxblog.Factory

  setup do
    role = insert(:role)
    user = insert(:user, role: role)
    {:ok, conn: build_conn(), user: user}
  end

  test "shows the Sign in form", %{conn: conn} do
    conn = get conn, session_path(conn, :new)
    assert html_response(conn, 200) =~ "Sign in"
  end

  test "creates a new user session for a valid user", %{conn: conn, user: user} do
    conn = post conn, session_path(conn, :create), user: %{email: user.email, password: user.password}
    assert get_session(conn, :current_user)
    assert get_flash(conn, :info) == "Sign in successful!"
    assert redirected_to(conn) == post_path(conn, :index)
  end

  test "does not create a session with a bad pasword", %{conn: conn, user: user} do
    conn = post conn, session_path(conn, :create), user: %{email: user.email, password: "wrong"}
    refute get_session(conn, :current_user)
    assert get_flash(conn, :error) == "Invalid email/password combination!"
    assert redirected_to(conn) == session_path(conn, :new)
  end
  
  test "does not create a session if user does not exist", %{conn: conn} do    
    conn = post conn, session_path(conn, :create), user: %{email: "foo@bar.com", password: "wrong"}
    assert get_flash(conn, :error) == "Invalid email/password combination!"
    assert redirected_to(conn) == session_path(conn, :new)
  end
end

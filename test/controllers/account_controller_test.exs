defmodule Pxblog.AccountControllerTest do
  use Pxblog.ConnCase

  alias Pxblog.User
  import Pxblog.Factory

  @valid_create_attrs %{email: "test@test.com", username: "test", password: "test123", password_confirmation: "test123"}
  @valid_update_attrs Map.merge(@valid_create_attrs, %{current_password: "test1234"})
  @valid_attrs %{email: "test@test.com", username: "test"}
  @invalid_attrs %{}

  setup do
    user_role     = insert(:role)
    nonadmin_user = insert(:user, role: user_role)

    admin_role = insert(:role, admin: true)
    admin_user = insert(:user, role: admin_role)

    {:ok, conn: build_conn(), admin_role: admin_role, user_role: user_role, nonadmin_user: nonadmin_user, admin_user: admin_user}
  end

  defp login_user(conn, user) do
    post conn, session_path(conn, :create), user: %{email: user.email, password: user.password}
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, account_path(conn, :new)
    assert html_response(conn, 200) =~ "Sign Up"
  end

  test "redirects from new form when already signed in", %{conn: conn, nonadmin_user: nonadmin_user} do
    conn = login_user(conn, nonadmin_user)
    conn = get conn, account_path(conn, :new)
    assert get_flash(conn, :error) == "You are already signed in!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, account_path(conn, :create), user: @valid_create_attrs
    assert redirected_to(conn) == session_path(conn, :new)
    assert Repo.get_by(User, @valid_attrs)
  end

  test "creates resource and picks a default non admin role", %{conn: conn} do
    conn = post conn, account_path(conn, :create), user: @valid_create_attrs
    user = Repo.get_by(User, @valid_attrs) |> Repo.preload([:role])
    assert user
    refute user.role.admin
  end

  test "redirects from create when already signed in", %{conn: conn, nonadmin_user: nonadmin_user} do
    conn = login_user(conn, nonadmin_user)
    conn = post conn, account_path(conn, :create), user: @valid_create_attrs
    assert get_flash(conn, :error) == "You are already signed in!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, account_path(conn, :create), user: @invalid_attrs
    assert html_response(conn, 200) =~ "Sign Up"
  end

  test "renders form for editing chosen resource when logged in", %{conn: conn, nonadmin_user: nonadmin_user} do
    conn = login_user(conn, nonadmin_user)
    conn = get conn, account_path(conn, :edit, nonadmin_user)
    assert html_response(conn, 200) =~ "Edit Account"
  end

  test "redirects away from editing when logged in as a different user", %{conn: conn, nonadmin_user: nonadmin_user, admin_user: admin_user} do
    conn = login_user(conn, nonadmin_user)
    conn = get conn, account_path(conn, :edit, admin_user)
    assert get_flash(conn, :error) == "You are not authorized to modify that user!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "redirects away from editing when not logged in", %{conn: conn, nonadmin_user: nonadmin_user} do
    conn = get conn, account_path(conn, :edit, nonadmin_user)
    assert get_flash(conn, :error) == "You are not authorized to modify that user!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "updates chosen resource and redirects when logged in and data is valid", %{conn: conn, admin_user: admin_user} do
    conn = login_user(conn, admin_user)
    conn = put conn, account_path(conn, :update, admin_user), user: @valid_update_attrs
    assert get_flash(conn, :info) == "User updated successfully."
    assert redirected_to(conn) == post_path(conn, :index)
    assert Repo.get_by(User, @valid_attrs)
  end

  test "validates current password at update", %{conn: conn, admin_user: admin_user} do
    conn = login_user(conn, admin_user)
    conn = put conn, account_path(conn, :update, admin_user), user: Map.merge(@valid_create_attrs, %{current_password: "wrong", username: "changed"}) 
    assert get_flash(conn, :error) == "Invalid current password!"
    assert redirected_to(conn) == account_path(conn, :edit, admin_user)
    refute Repo.get_by(User, username: "changed")
  end

  test "redirects away from update when logged in as a different user", %{conn: conn, nonadmin_user: nonadmin_user, admin_user: admin_user} do
    conn = login_user(conn, admin_user)
    conn = put conn, account_path(conn, :update, nonadmin_user), user: @valid_update_attrs
    assert get_flash(conn, :error) == "You are not authorized to modify that user!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "deletes chosen resource when logged in as target user", %{conn: conn, nonadmin_user: nonadmin_user} do
    conn =
      login_user(conn, nonadmin_user)
      |> delete(account_path(conn, :delete, nonadmin_user))
    assert get_flash(conn, :info) == "Account deleted successfully."
    assert redirected_to(conn) == post_path(conn, :index)
    refute get_session(conn, :current_user)
    refute Repo.get(User, nonadmin_user.id)
  end

  test "redirects away from deleting chosen resource when logged in as a different user", %{conn: conn, user_role: user_role, nonadmin_user: nonadmin_user} do
    user = insert(:user, role: user_role)
    conn =
      login_user(conn, nonadmin_user)
      |> delete(account_path(conn, :delete, user))
    assert get_flash(conn, :error) == "You are not authorized to modify that user!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end
end

defmodule Pxblog.AccountControllerTest do
  use Pxblog.ConnCase
  alias Pxblog.User
  import Pxblog.Factory

  @valid_create_attrs %{
    email: "test@test.com", 
    username: "test", 
    password: "test123", 
    password_confirmation: "test123"
  }
  @valid_update_attrs Map.merge(@valid_create_attrs, %{current_password: "test1234"})
  @valid_attrs %{email: "test@test.com", username: "test"}
  @invalid_attrs %{}

  setup do
    user_role     = insert(:role)
    user = insert(:user, role: user_role)

    admin_role = insert(:role, admin: true)
    admin_user = insert(:user, role: admin_role)

    {
      :ok, 
      conn: build_conn(), 
      admin_role: admin_role, 
      user_role: user_role, 
      user: user, 
      admin_user: admin_user
    }
  end

  defp login_user(conn, user) do
    post conn, 
         session_path(conn, :create), 
         user: %{email: user.email, password: user.password}
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, account_path(conn, :new)
    assert html_response(conn, 200) =~ "Sign Up"
  end

  test "redirects from new form when already signed in", %{conn: conn, user: user} do
    conn = login_user(conn, user)
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
    post conn, account_path(conn, :create), user: @valid_create_attrs
    user = Repo.get_by(User, @valid_attrs) |> Repo.preload([:role])
    assert user
    refute user.role.admin
  end

  test "redirects from create when already signed in", %{conn: conn, user: user} do
    conn = login_user(conn, user)
    conn = post conn, account_path(conn, :create), user: @valid_create_attrs
    assert get_flash(conn, :error) == "You are already signed in!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, account_path(conn, :create), user: @invalid_attrs
    assert html_response(conn, 200) =~ "Sign Up"
  end

  test "renders form for editing chosen resource when logged in", %{conn: conn, user: user} do
    conn = login_user(conn, user)
    conn = get conn, account_path(conn, :edit, user)
    assert html_response(conn, 200) =~ "Edit Account"
  end

  test "redirects away from editing when logged in as a different user", 
       %{conn: conn, user: user, admin_user: admin_user} do
    conn = login_user(conn, user)
    conn = get conn, account_path(conn, :edit, admin_user)
    assert get_flash(conn, :error) == "You are not authorized to modify that user!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "redirects away from editing when not logged in", %{conn: conn, user: user} do
    conn = get conn, account_path(conn, :edit, user)
    assert get_flash(conn, :error) == "You are not authorized to modify that user!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "updates chosen resource and redirects when logged in and data is valid", 
       %{conn: conn, admin_user: admin_user} do
    conn = login_user(conn, admin_user)
    conn = put conn, account_path(conn, :update, admin_user), user: @valid_update_attrs
    assert get_flash(conn, :info) == "User updated successfully."
    assert redirected_to(conn) == post_path(conn, :index)
    assert Repo.get_by(User, @valid_attrs)
  end

  test "validates current password at update", %{conn: conn, admin_user: admin_user} do
    conn = login_user(conn, admin_user)
    conn = put conn, 
           account_path(conn, :update, admin_user), 
           user: Map.merge(@valid_create_attrs, %{current_password: "wrong", username: "changed"}) 
    assert get_flash(conn, :error) == "Invalid current password!"
    assert redirected_to(conn) == account_path(conn, :edit, admin_user)
    refute Repo.get_by(User, username: "changed")
  end

  test "redirects away from update when logged in as a different user", 
       %{conn: conn, user: user, admin_user: admin_user} do
    conn = login_user(conn, admin_user)
    conn = put conn, account_path(conn, :update, user), user: @valid_update_attrs
    assert get_flash(conn, :error) == "You are not authorized to modify that user!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "deletes chosen resource when logged in as target user", %{conn: conn, user: user} do
    conn =
      login_user(conn, user)
      |> delete(account_path(conn, :delete, user))
    assert get_flash(conn, :info) == "Account deleted successfully."
    assert redirected_to(conn) == post_path(conn, :index)
    refute get_session(conn, :current_user)
    refute Repo.get(User, user.id)
  end

  test "redirects away from deleting chosen resource when logged in as a different user", 
       %{conn: conn, user_role: user_role, user: user} do
    new_user = insert(:user, role: user_role)
    conn =
      login_user(conn, new_user)
      |> delete(account_path(conn, :delete, user))
    assert get_flash(conn, :error) == "You are not authorized to modify that user!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "GET recover_password renders form for the first step of password reset", 
       %{conn: conn} do
    conn = get conn, recover_password_path(conn, :recover_password)
    response = html_response(conn, 200)
    assert response =~ "Recover Password"
    assert response =~ "Email"
    assert response =~ "Send me reset password instructions"
  end

  test "GET recover_password redirects away when already signed in", 
       %{conn: conn, user: user} do
    conn = login_user(conn, user)
    conn = get conn, recover_password_path(conn, :recover_password)
    assert get_flash(conn, :error) == "You are already signed in!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "POST recover_password creates a password reset token when data is valid", 
       %{conn: conn, user: user} do
    refute user.reset_password_token
    conn = post conn, 
           recover_password_path(conn, :recover_password), 
           user: %{email: user.email}
    
    assert get_flash(conn, :info) == "You will receive an email with instructions" <>
                                     " on how to reset your password in a few minutes."
    assert redirected_to(conn) == session_path(conn, :new)

    user = Repo.get(User, user.id)
    assert user.reset_password_token
    assert user.reset_password_sent_at
  end

  test "POST recover_password displays validation errors when data is invalid", 
       %{conn: conn, user: user} do
    refute user.reset_password_token
    conn = post conn, 
           recover_password_path(conn, :recover_password), 
           user: %{email: "dummy@test.com"}
    
    assert get_flash(conn, :error) == "User account not found."
    assert redirected_to(conn) == recover_password_path(conn, :recover_password)

    user = Repo.get(User, user.id)
    refute user.reset_password_token
    refute user.reset_password_sent_at
  end

  test "GET reset_password renders form for the second step of password reset", 
       %{conn: conn, user: user} do
    token = User.create_reset_password_token(user)
    conn = get conn, reset_password_path(conn, :reset_password), token: token
    response = html_response(conn, 200)
    assert response =~ "Recover Password"
    assert response =~ "Password"
    assert response =~ "Password Confirmation"
    assert response =~ "Reset password"
  end

  test "GET reset_password redirects away when token is invalid", 
       %{conn: conn, user: user} do
    User.create_reset_password_token(user)
    conn = get conn, reset_password_path(conn, :reset_password), token: "dummy_token"
    assert get_flash(conn, :error) == "Invalid reset password token."
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "GET reset_password redirects away when token does not exist", %{conn: conn} do
    conn = get conn, reset_password_path(conn, :reset_password), token: "dummy_token"
    assert get_flash(conn, :error) == "Invalid reset password token."
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "GET reset_password redirects away when token is expired", 
       %{conn: conn, user: user} do
    token = User.create_reset_password_token(user)
    user = Repo.get(User, user.id)
    changes = %{reset_password_sent_at: Timex.shift(user.reset_password_sent_at, minutes: -61)}
    Repo.update(User.changeset(user, changes))
    conn = get conn, reset_password_path(conn, :reset_password), token: token
    assert get_flash(conn, :error) == "Reset password token has expired."
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "PUT reset_password creates a new password when data is valid", 
       %{conn: conn, user: user} do
    token = User.create_reset_password_token(user)
    conn = put conn, 
           reset_password_path(conn, :reset_password), 
           %{
             token: token, 
             user: %{
               password: "test1234", 
               password_confirmation: "test1234"
              }
           }
    
    assert get_flash(conn, :info) == "Your password has been changed successfully." <>
                                     " You are now signed in."
    assert redirected_to(conn) == post_path(conn, :index)

    user = Repo.get(User, user.id)
    refute user.reset_password_token
    refute user.reset_password_sent_at
    get_session(conn, :current_user)
  end

  test "PUT reset_password redirects away when token is invalid", %{conn: conn} do
    conn = put conn, 
           reset_password_path(conn, :reset_password), 
           %{
             token: "dummy_token", 
             user: %{
               password: "test1234", 
               password_confirmation: "test1234"
             }
           }
    assert get_flash(conn, :error) == "Invalid reset password token."
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "PUT reset_password displays validation errors when data is invalid", 
       %{conn: conn, user: user} do
    token = User.create_reset_password_token(user)
    conn = put conn, 
           reset_password_path(conn, :reset_password), 
           %{
             token: token, 
             user: %{
               password: "test1234", 
               password_confirmation: "test4321"
             }
           }
   
    response = html_response(conn, 400)
    assert response =~ "Recover Password"
    assert response =~ "Oops, something went wrong! Please check the errors below."
  end
end

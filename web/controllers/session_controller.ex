defmodule Pxblog.SessionController do
  use Pxblog.Web, :controller
  alias Plug.Conn
  alias Pxblog.User
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  plug :scrub_params, "user" when action in [:create]
  plug :add_breadcrumb, name: 'Home', url: '/'

  def new(conn, _params) do
    conn = add_breadcrumb(conn, name: 'Sign In', url: session_path(conn, :new))
    render conn, "new.html", changeset: User.changeset(%User{})
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}})
  when not is_nil(email) and not is_nil(password) do
    user = Repo.get_by(User, email: email) |> Repo.preload(:role)
    sign_in(user, password, conn)
  end

  def create(conn, _) do
    failed_login(conn)
  end

  def delete(conn, _params) do
    conn
    |> Conn.delete_session(:current_user)
    |> Conn.assign(:current_user, nil)
    |> put_flash(:info, "Signed out successfully!")
    |> redirect(to: post_path(conn, :index))
  end

  defp sign_in(user, _password, conn) when is_nil(user) do
    failed_login(conn)
  end

  defp sign_in(user, password, conn) do
    if checkpw(password, user.encrypted_password) do
      conn
      |> Conn.put_session(
           :current_user,
           %{
             id: user.id,
             username: user.username,
             role_id: user.role.id,
             admin: user.role.admin
           }
         )
      |> Conn.assign(:current_user, user)
      |> put_flash(:info, "Sign in successful!")
      |> redirect(to: post_path(conn, :index))
    else
      failed_login(conn)
    end
  end

  defp failed_login(conn) do
    dummy_checkpw()
    conn
    |> Conn.put_session(:current_user, nil)
    |> Conn.assign(:current_user, nil)
    |> put_flash(:error, "Invalid email/password combination!")
    |> redirect(to: session_path(conn, :new))
    |> halt()
  end
end

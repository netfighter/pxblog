defmodule Pxblog.AccountController do
  use Pxblog.Web, :controller
  use Timex
  alias Pxblog.User
  alias Pxblog.Role
  alias Pxblog.UserEmail
  alias Pxblog.Mailer
  import Comeonin.Bcrypt, only: [checkpw: 2, hashpwsalt: 1]

  plug :authorize_user when action in [:edit, :update, :delete]
  plug :redirect_if_signed_in when action in [:new, :create]
  plug :validate_reset_password_token when action in[:reset_password]
  plug :add_breadcrumb, name: 'Home', url: '/'

  def new(conn, _params) do
    conn = add_breadcrumb(conn, name: 'Sign Up', url: account_path(conn, :new))
    changeset = User.changeset(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset_with_password(%User{}, user_params |> set_default_role)

    case Repo.insert(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: session_path(conn, :new))
      {:error, changeset} ->
        conn = add_breadcrumb(conn, name: 'Sign Up', url: account_path(conn, :new))
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Repo.get!(User, id)
    changeset = User.changeset(user)
    conn = add_breadcrumb(conn, name: 'Edit Account', url: account_path(conn, :edit, user))
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Repo.get!(User, id)
    check_password(user, user_params["current_password"], conn)
    
    if is_nil(user_params["password"]) || user_params["password"] == "" do
      changeset = User.changeset(user, user_params)
    else
      changeset = User.changeset_with_password(user, user_params)
    end  

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: post_path(conn, :index))
      {:error, changeset} ->
        conn = add_breadcrumb(conn, name: 'Edit Account', url: account_path(conn, :edit, user))
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def recover_password(%{method: "GET"} = conn, _) do
    conn = add_breadcrumb(conn, name: 'Recover Password', url: recover_password_path(conn, :recover_password))
    changeset = User.changeset_with_password(%User{})
    render(conn, "recover_password.html", changeset: changeset)
  end

  def recover_password(%{method: "POST"} = conn, %{"user" => user_params}) do
    if user = Repo.get_by(User, email: user_params["email"]) do
      reset_token = create_reset_password_token(user)
      reset_path = reset_password_path(conn, :reset_password)
      reset_password_url = "#{conn.scheme}://#{conn.host}:#{conn.port}#{reset_path}?token=#{reset_token}"
      UserEmail.send_reset_password_email(user, reset_password_url) |> Mailer.deliver

      conn
      |> put_flash(:info, "You will receive an email with instructions on how to reset your password in a few minutes.")
      |> redirect(to: session_path(conn, :new))
    else
      conn
      |> put_flash(:error, "User account not found.")
      |> redirect(to: recover_password_path(conn, :recover_password))
    end
  end

  def reset_password(%{method: "GET"} = conn, %{"token" => token}) do
    user = Repo.get_by(User, reset_password_token: token)
    conn = add_breadcrumb(conn, name: 'Recover Password', url: recover_password_path(conn, :recover_password))
    changeset = User.changeset_with_password(user)
    render(conn, "reset_password.html", token: token, changeset: User.changeset(user))
  end

  def reset_password(%{method: "PUT"} = conn, %{"token" => token, "user" => user_params}) do
    user = Repo.get_by(User, reset_password_token: token)
    changeset = User.changeset_with_password(user, user_params)
      |> Ecto.Changeset.put_change(:reset_password_token, nil)   
      |> Ecto.Changeset.put_change(:reset_password_sent_at, nil)  

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> put_session(:current_user, %{id: user.id, username: user.username, role_id: user.role_id})
        |> put_flash(:info, "Your password has been changed successfully. You are now signed in.")
        |> redirect(to: post_path(conn, :index))
      {:error, changeset} ->
        conn = add_breadcrumb(conn, name: 'Recover Password', url: recover_password_path(conn, :recover_password))
        render(conn, "reset_password.html", token: token, changeset: changeset)
    end 
  end

  def delete(conn, %{"id" => id}) do
    user = Repo.get!(User, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(user)

    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "Account deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end

  defp authorize_user(conn, _) do
    user = get_session(conn, :current_user)
    if user && (Integer.to_string(user.id) == conn.params["id"] || Pxblog.RoleChecker.is_admin?(user)) do
      conn
    else
      send_home_with_error(conn, "You are not authorized to modify that user!")
    end
  end

  defp redirect_if_signed_in(conn, _) do
    user = get_session(conn, :current_user)
    if user do
      send_home_with_error(conn, "You are already signed in!")
    else
      conn
    end
  end

  defp set_default_role(params) do
    default_role = Repo.one(from r in Pxblog.Role, where: [admin: false], order_by: [asc: r.id], limit: 1)
    Map.merge(params, %{"role_id" => default_role.id})
  end

  defp check_password(user, password, conn) do
    if !checkpw(password, user.encrypted_password) do
      conn
      |> put_flash(:error, "Invalid current password!")
      |> redirect(to: account_path(conn, :edit, user))
      |> halt()
    end
  end

  defp create_reset_password_token(user) do
    current_time = to_string(:erlang.system_time(:seconds))
    token = Base.encode16 "#{current_time},#{user.id}"
    changeset = User.changeset(user, %{reset_password_token: token, reset_password_sent_at: NaiveDateTime.utc_now()})
    Repo.update(changeset)

    token 
  end

  defp validate_reset_password_token(conn, _) do
    if conn.params["token"] && (user = Repo.get_by(User, reset_password_token: conn.params["token"])) do
      # token is considered expired after one hour
      if Timex.diff(NaiveDateTime.utc_now(), user.reset_password_sent_at, :minutes) <= 60 do
        conn
      else
        send_home_with_error(conn, "Reset password token has expired.")
      end
    else
      send_home_with_error(conn, "Invalid reset password token.")
    end
  end

  defp send_home_with_error(conn, message \\ "Unexpected error.") do
    conn
    |> put_flash(:error, message)
    |> redirect(to: post_path(conn, :index))
    |> halt()
  end
end
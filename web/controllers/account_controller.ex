defmodule Pxblog.AccountController do
  use Pxblog.Web, :controller
  use Timex
  alias Ecto.Changeset
  alias Pxblog.User
  alias Pxblog.Role
  alias Pxblog.UserEmail
  alias Pxblog.Mailer
  import Comeonin.Bcrypt, only: [checkpw: 2, hashpwsalt: 1]

  plug :authorize_user when action in [:edit, :update, :delete]
  plug :check_current_password when action in [:update]
  plug :redirect_if_signed_in when action in [:new, :create, :recover_password, :reset_password]
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
      {:ok, user} ->
        send_welcome_email(conn, user)

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
    conn = add_breadcrumb(
      conn,
      name: 'Recover Password',
      url: recover_password_path(conn, :recover_password)
    )
    changeset = User.changeset_with_password(%User{})
    render(conn, "recover_password.html", changeset: changeset)
  end

  def recover_password(%{method: "POST"} = conn, %{"user" => user_params}) do
    if user = Repo.get_by(User, email: user_params["email"]) do
      reset_token = User.create_reset_password_token(user)
      send_reset_password_email(conn, user, reset_token)

      conn
      |> put_flash(:info, "You will receive an email with instructions on how to" <>
                          " reset your password in a few minutes.")
      |> redirect(to: session_path(conn, :new))
    else
      conn
      |> put_flash(:error, "User account not found.")
      |> redirect(to: recover_password_path(conn, :recover_password))
    end
  end

  def reset_password(%{method: "GET"} = conn, %{"token" => token}) do
    user = Repo.get_by(User, reset_password_token: token)
    conn = add_breadcrumb(
      conn,
      name: 'Recover Password',
      url: recover_password_path(conn, :recover_password)
    )
    changeset = User.changeset_with_password(user)
    render(conn, "reset_password.html", token: token, changeset: User.changeset(user))
  end

  def reset_password(%{method: "PUT"} = conn, %{"token" => token, "user" => user_params}) do
    user = Repo.get_by(User, reset_password_token: token)
    changeset = User.changeset_with_password(user, user_params)
      |> Changeset.put_change(:reset_password_token, nil)
      |> Changeset.put_change(:reset_password_sent_at, nil)

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> put_session(:current_user, %{id: user.id, username: user.username, role_id: user.role_id})
        |> put_flash(:info, "Your password has been changed successfully. You are now signed in.")
        |> redirect(to: post_path(conn, :index))
      {:error, changeset} ->
        conn = add_breadcrumb(
          conn,
          name: 'Recover Password',
          url: recover_password_path(conn, :recover_password)
        )

        conn
        |> put_status(400)
        |> render("reset_password.html", token: token, changeset: changeset)
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
    if user && (Integer.to_string(user.id) == conn.params["id"]) do
      conn
    else
      send_home_with_error(conn, "You are not authorized to modify that user!")
    end
  end

   defp check_current_password(conn, _) do
     user = Repo.get!(User, get_session(conn, :current_user).id)
     password = conn.params["user"]["current_password"]
    if checkpw(password, user.encrypted_password) do
      conn
    else
      conn
      |> put_flash(:error, "Invalid current password!")
      |> redirect(to: account_path(conn, :edit, user))
      |> halt()
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
    default_role = Repo.one(
      from r in Role,
      where: [admin: false],
      order_by: [asc: r.id],
      limit: 1
    )
    Map.merge(params, %{"role_id" => default_role.id})
  end

  defp validate_reset_password_token(conn, _) do
    if conn.params["token"] &&
       (user = Repo.get_by(User, reset_password_token: conn.params["token"])) do
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

  defp send_welcome_email(conn, user) do
    sign_in_url = "#{conn.scheme}://#{conn.host}:#{conn.port}#{session_path(conn, :new)}"
    # put mail sending job in a background task
    Task.Supervisor.start_child Pxblog.MailerTask, fn ->
      UserEmail.send_welcome_email(user, sign_in_url) |> Mailer.deliver
    end
  end

  defp send_reset_password_email(conn, user, token) do
    reset_path = reset_password_path(conn, :reset_password)
    port = if conn.port == 80, do: "", else: ":#{conn.port}"
    reset_password_url = "#{conn.scheme}://#{conn.host}#{port}#{reset_path}?token=#{token}"
    # put mail sending job in a background task
    Task.Supervisor.start_child Pxblog.MailerTask, fn ->
      UserEmail.send_reset_password_email(user, reset_password_url) |> Mailer.deliver
    end
  end
end

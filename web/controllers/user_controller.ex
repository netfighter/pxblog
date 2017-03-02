defmodule Pxblog.UserController do
  use Pxblog.Web, :controller
  alias Pxblog.User
  alias Pxblog.Role

  plug :authorize_admin 
  plug :add_breadcrumb, name: 'Home', url: '/'
  plug :add_breadcrumb, name: 'Users', url: '/users'

  def index(conn, _params) do
    users = Repo.all(User) |> Repo.preload(:role)
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    conn = add_breadcrumb(conn, name: 'New User', url: user_path(conn, :new))
    roles = Repo.all(Role)
    changeset = User.changeset_with_password(%User{})
    render(conn, "new.html", changeset: changeset, roles: roles)
  end

  def create(conn, %{"user" => user_params}) do
    roles = Repo.all(Role)
    changeset = User.changeset_with_password(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        conn = add_breadcrumb(conn, name: 'New User', url: user_path(conn, :new))
        render(conn, "new.html", changeset: changeset, roles: roles)
    end
  end

  def edit(conn, %{"id" => id}) do
    roles = Repo.all(Role)
    user = Repo.get!(User, id)
    changeset = User.changeset(user)
    conn = add_breadcrumb(conn, name: 'Edit User', url: user_path(conn, :edit, user))
    render(conn, "edit.html", user: user, changeset: changeset, roles: roles)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    roles = Repo.all(Role)
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
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        conn = add_breadcrumb(conn, name: 'Edit User', url: user_path(conn, :edit, user))
        render(conn, "edit.html", user: user, changeset: changeset, roles: roles)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Repo.get!(User, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: user_path(conn, :index))
  end

  defp authorize_admin(conn, _) do
    user = get_session(conn, :current_user)
    if user && Pxblog.RoleChecker.is_admin?(user) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to edit users!")
      |> redirect(to: post_path(conn, :index))
      |> halt()
    end
  end
end

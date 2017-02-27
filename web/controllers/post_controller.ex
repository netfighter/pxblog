defmodule Pxblog.PostController do
  use Pxblog.Web, :controller

  alias Pxblog.Post
  alias Pxblog.Role
  alias Pxblog.User

  plug :assign_user
  plug :authorize_user when action in [:new, :create, :edit, :update, :delete]
  plug :set_authorization_flag
  plug :find_post_with_comments when action in [:show]
  plug :find_post when action in [:edit, :update, :delete]
  plug :add_breadcrumb, name: 'Home', url: '/'

  def index(conn, _params) do
    posts = Repo.all(Post)
    render(conn, "index.html", posts: posts)
  end

  def new(conn, _params) do
    conn = add_breadcrumb(conn, name: 'New Post', url: post_path(conn, :new))
    changeset =
      conn.assigns[:user]
      |> build_assoc(:posts)
      |> Post.changeset()
  end

  def create(conn, %{"post" => post_params}) do
    changeset =
      conn.assigns[:user]
      |> build_assoc(:posts)
      |> Post.changeset(post_params)
    case Repo.insert(changeset) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: post_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    conn = add_breadcrumb(conn, name: conn.assigns[:post].title, url: post_path(conn, :show, conn.assigns[:post]))
    comment_changeset = conn.assigns[:post]
      |> build_assoc(:comments)
      |> Pxblog.Comment.changeset()
    render(conn, "show.html", post: conn.assigns[:post], comment_changeset: comment_changeset)
  end

  def edit(conn, %{"id" => id}) do
    conn = add_breadcrumb(conn, name: conn.assigns[:post].title, url: post_path(conn, :show, conn.assigns[:post]))
    changeset = Post.changeset(conn.assigns[:post])
    render(conn, "edit.html", post: conn.assigns[:post], changeset: changeset)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    changeset = Post.changeset(conn.assigns[:post], post_params)
    case Repo.update(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        render(conn, "edit.html", post: conn.assigns[:post], changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(conn.assigns[:post])
    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end

  defp find_post(conn, _opts) do
    post = Repo.get!(Post, conn.params["id"])
    assign(conn, :post, post)
  end
  
  defp find_post_with_comments(conn, _opts) do
    post = Repo.get!(Post, conn.params["id"])
      |> Repo.preload(:comments)
    assign(conn, :post, post)
  end

  defp assign_user(conn, _opts) do
    if current_user(conn) do
      user = Repo.get(User, current_user(conn).id)
      conn
      |> assign(:user, user)
    else
      conn
    end
  end

  defp authorize_user(conn, _opts) do
    if is_authorized_user?(conn) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to create/edit posts!")
      |> redirect(to: post_path(conn, :index))
      |> halt
    end
  end

  defp is_authorized_user?(conn) do
    user = current_user(conn)
    (user && Pxblog.RoleChecker.is_admin?(current_user(conn)))
  end

  defp set_authorization_flag(conn, _opts) do
    assign(conn, :author_or_admin, is_authorized_user?(conn))
  end

  defp current_user(conn) do
    get_session(conn, :current_user)
  end
end

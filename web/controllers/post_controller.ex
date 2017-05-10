defmodule Pxblog.PostController do
  use Pxblog.Web, :controller
  alias Pxblog.Post
  
  plug :load_and_authorize_resource, model: Post, except: [:show]
  plug :load_and_authorize_resource, model: Post,
       id_name: "id",
       persisted: true,
       preload: [comments: [:user]],
       only: [:show]
  plug :add_breadcrumb, name: 'Home', url: '/'

  def index(conn, _params) do
    posts = Repo.all(Post)
    render(conn, "index.html", posts: posts)
  end

  def new(conn, _params) do
    conn = add_breadcrumb(conn, name: 'New Post', url: post_path(conn, :new))
    changeset =
      conn.assigns[:current_user]
      |> build_assoc(:posts)
      |> Post.changeset()
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    changeset =
      conn.assigns[:current_user]
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
    conn = add_breadcrumb(
      conn, 
      name: conn.assigns[:post].title, 
      url: post_path(conn, :show, conn.assigns[:post])
    )
    comment_changeset = conn.assigns[:post]
      |> build_assoc(:comments)
      |> Pxblog.Comment.changeset()

    render conn, 
           "show.html", 
           post: conn.assigns[:post], 
           comment_changeset: comment_changeset
  end

  def edit(conn, %{"id" => id}) do
    conn = add_breadcrumb(
      conn, 
      name: conn.assigns[:post].title, 
      url: post_path(conn, :show, conn.assigns[:post])
    )
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
end

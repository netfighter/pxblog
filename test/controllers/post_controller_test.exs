defmodule Pxblog.PostControllerTest do
  use Pxblog.ConnCase
  alias Pxblog.Post
  import Pxblog.Factory

  @valid_attrs %{body: "some content", title: "some content"}
  @invalid_attrs %{}

  setup do
    role = insert(:role)
    user = insert(:user, role: role)
    other_user = insert(:user, role: role)
    post = insert(:post, user: user)
    admin_role = insert(:role, admin: true)
    admin = insert(:user, role: admin_role)
    conn = build_conn() |> login_user(user)
    {:ok, conn: conn, user: user, other_user: other_user, role: role, post: post, admin: admin}
  end

  defp login_user(conn, user) do
    post conn, session_path(conn, :create), user: %{email: user.email, password: user.password}
  end

  defp logout_user(conn, user) do
    delete conn, session_path(conn, :delete, user)
  end
  
  test "lists all entries on index", %{conn: conn} do
    conn = get conn, post_path(conn, :index)
    assert html_response(conn, 200) =~ "Posts"
  end
  
  test "renders form for new resources when logged in as admin", %{conn: conn, admin: admin} do
    conn = login_user(conn, admin) |> get(post_path(conn, :new))
    assert html_response(conn, 200) =~ "New post"
  end

  test "does not render form for new resources when logged in as user", %{conn: conn} do
    conn = get conn, post_path(conn, :new)
    assert get_flash(conn, :error) == "You are not authorized to access this resource!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end
  
  test "creates resource and redirects when data is valid", %{conn: conn, admin: admin} do
    conn = login_user(conn, admin) |> post(post_path(conn, :create), post: @valid_attrs)
    assert redirected_to(conn) == post_path(conn, :index)
    assert Repo.get_by(assoc(admin, :posts), @valid_attrs)
  end
  
  test "does not create resource and renders errors when data is invalid", %{conn: conn, admin: admin} do
    conn = login_user(conn, admin) |> post(post_path(conn, :create), post: @invalid_attrs)
    assert html_response(conn, 200) =~ "New post"
  end

  test "does not create resource and renders errors when logged in as user", %{conn: conn} do
    conn = post conn, post_path(conn, :create), post: @valid_attrs
    assert get_flash(conn, :error) == "You are not authorized to access this resource!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "when not logged in, shows chosen resource", %{conn: conn, user: user, post: post} do
    conn = logout_user(conn, user) |> get(post_path(conn, :show, post))
    assert html_response(conn, 200) =~ post.title
    refute conn.assigns[:admin]
  end
  
  test "renders page not found when id is nonexistent", %{conn: conn} do
    conn = get conn, post_path(conn, :show, -1)
    assert get_flash(conn, :error) == "Resource not found!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end
  
  test "forbids editing blog post as user", %{conn: conn, post: post} do
    conn = get conn, post_path(conn, :edit, post)
    assert get_flash(conn, :error) == "You are not authorized to access this resource!"
    assert redirected_to(conn) == post_path(conn, :index)
    assert conn.halted
  end

  test "renders form for editing chosen resource", %{conn: conn, admin: admin, post: post} do
    conn = login_user(conn, admin) |> get(post_path(conn, :edit, post))
    assert html_response(conn, 200) =~ "Edit post"
  end
  
  test "updates chosen resource and redirects when data is valid", %{conn: conn, admin: admin, post: post} do
    conn = login_user(conn, admin) |> put(post_path(conn, :update, post), post: @valid_attrs)
    assert redirected_to(conn) == post_path(conn, :show, post)
    assert Repo.get_by(Post, @valid_attrs)
  end
  
  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, admin: admin, post: post} do
    conn = login_user(conn, admin) |> put(post_path(conn, :update, post), post: %{"body" => nil})
    assert html_response(conn, 200) =~ "Edit post"
  end

  test "does not delete chosen resource when loggen in as user", %{conn: conn, post: post} do
    conn = delete conn, post_path(conn, :delete, post)
    assert redirected_to(conn) == post_path(conn, :index)
    assert Repo.get(Post, post.id)
  end

  test "renders form for editing chosen resource when logged in as admin", %{conn: conn, post: post} do
    role = insert(:role, name: "Admin", admin: true)
    admin = insert(:user, email: "admin@test.com", username: "admin", role: role)
    conn =
      login_user(conn, admin)
      |> get(post_path(conn, :edit, post))
    assert html_response(conn, 200) =~ "Edit post"
  end

  test "updates chosen resource and redirects when data is valid when logged in as admin", %{conn: conn, post: post} do
    role = insert(:role, name: "Admin", admin: true)
    admin = insert(:user, email: "admin@test.com", username: "admin", role: role)
    conn =
      login_user(conn, admin)
      |> put(post_path(conn, :update, post), post: @valid_attrs)
    assert redirected_to(conn) == post_path(conn, :show, post)
    assert Repo.get_by(Post, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid when logged in as admin", %{conn: conn, post: post} do
    role = insert(:role, name: "Admin", admin: true)
    admin = insert(:user, email: "admin@test.com", username: "admin", role: role)
    conn =
      login_user(conn, admin)
      |> put(post_path(conn, :update, post), post: %{"body" => nil})
    assert html_response(conn, 200) =~ "Edit post"
  end

  test "deletes chosen resource when logged in as admin", %{conn: conn, post: post} do
    role = insert(:role, name: "Admin", admin: true)
    admin = insert(:user, email: "admin@test.com", username: "admin", role: role)
    conn =
      login_user(conn, admin)
      |> delete(post_path(conn, :delete, post))
    assert redirected_to(conn) == post_path(conn, :index)
    refute Repo.get(Post, post.id)
  end
end

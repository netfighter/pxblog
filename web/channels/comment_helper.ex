defmodule Pxblog.CommentHelper do
  alias Pxblog.Comment
  alias Pxblog.Post
  alias Pxblog.User
  alias Pxblog.Repo

  import Ecto, only: [build_assoc: 2]

  def create(%{"postId" => post_id, "body" => body}, %{assigns: %{user: user_id}}) do
    post = get_post(post_id)
    user = get_user(user_id)
    changeset = post
      |> build_assoc(:comments)
      |> Comment.changeset(%{body: body, user_id: user.id})

    case Repo.insert(changeset) do
      {:ok, comment} ->
        comment = comment |> Repo.preload([:user])
        {:ok, Map.merge(%{}, %{id: comment.id, author: comment.user.username, author_id: comment.user_id, inserted_at: comment.inserted_at})}
      {:error, changeset} ->
        {:error, "User is not authorized"}
    end
  end

  def create(_params, %{}), do: {:error, "User is not authorized"}
  def create(_params, nil), do: {:error, "User is not authorized"}

  def delete(%{"postId" => post_id, "commentId" => comment_id}, %{assigns: %{user: user_id}}) do
    authorize_and_perform(comment_id, user_id, fn ->
      comment = get_comment(comment_id)
      Repo.delete(comment)
    end)
  end

  def delete(_params, %{}), do: {:error, "User is not authorized"}
  def delete(_params, nil), do: {:error, "User is not authorized"}

  defp authorize_and_perform(comment_id, user_id, action) do
    comment = get_comment(comment_id)
    user = get_user(user_id)
    if is_authorized_user?(user, comment) do
      action.()
    else
      {:error, "User is not authorized"}
    end
  end

  defp get_user(user_id) do
    Repo.get!(User, user_id)
  end

  defp get_post(post_id) do
    Repo.get!(Post, post_id) |> Repo.preload([:user, :comments])
  end

  defp get_comment(comment_id) do
    Repo.get!(Comment, comment_id)
  end

  defp is_authorized_user?(user, comment) do
    (user && (user.id == comment.user_id || Pxblog.RoleChecker.is_admin?(user)))
  end
end

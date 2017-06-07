defmodule Pxblog.CommentHelper do
  alias Pxblog.Comment
  alias Pxblog.Post
  alias Pxblog.User
  alias Pxblog.Repo
  import Ecto, only: [build_assoc: 2]
  import Canada.Can, only: [can?: 3]

  def create(%{"postId" => post_id, "body" => body}, %{assigns: %{user: user_id}}) do
    post = get_post(post_id)
    user = get_user(user_id)

    if user |> can?(:create, Pxblog.Comment) do
      create_comment(post, user, body)
    else
      {:error, "User is not authorized"}
    end
  end

  def create(_params, %{}), do: {:error, "User is not authorized"}
  def create(_params, nil), do: {:error, "User is not authorized"}

  def delete(%{"postId" => post_id, "commentId" => comment_id}, %{assigns: %{user: user_id}}) do
    user = get_user(user_id)
    comment = get_comment(comment_id)

    if user |> can?(:delete, comment) do
      Repo.delete(comment)
    else
      {:error, "User is not authorized"}
    end
  end

  def delete(_params, %{}), do: {:error, "User is not authorized"}
  def delete(_params, nil), do: {:error, "User is not authorized"}

  defp get_user(user_id) do
    Repo.get!(User, user_id) |> Repo.preload(:role)
  end

  defp get_post(post_id) do
    Repo.get!(Post, post_id)
  end

  defp get_comment(comment_id) do
    Repo.get!(Comment, comment_id)
  end

  defp create_comment(post, user, body) do
    changeset = post
      |> build_assoc(:comments)
      |> Comment.changeset(%{body: body, user_id: user.id})

    case Repo.insert(changeset) do
      {:ok, comment} ->
        comment = comment |> Repo.preload([:user])
        response = %{
          id: comment.id,
          author: comment.user.username,
          author_id: comment.user_id,
          inserted_at: comment.inserted_at
        }
        {:ok, Map.merge(%{}, response)}
      {:error, changeset} ->
        {:error, "User is not authorized"}
    end
  end
end

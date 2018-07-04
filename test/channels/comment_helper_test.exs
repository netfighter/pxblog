defmodule PxblogWeb.CommentHelperTest do
  use Pxblog.ModelCase

  alias Pxblog.Comment
  alias PxblogWeb.CommentHelper

  import Pxblog.Factory

  setup do
    user        = insert(:user)
    post        = insert(:post, user: user)
    comment     = insert(:comment, post: post, user: user)
    fake_socket = %{assigns: %{user: user.id}}

    {:ok, user: user, post: post, comment: comment, socket: fake_socket}
  end

  test "creates a comment for a post", %{post: post, socket: socket} do
    {:ok, comment} = CommentHelper.create(%{
      "postId" => post.id,
      "body" => "Some Post"
    }, socket)
    assert comment
    assert Repo.get(Comment, comment.id)
  end

  test "deletes a comment when an authorized user", 
       %{post: post, comment: comment, socket: socket} do
    {:ok, comment} = CommentHelper.delete(%{"postId" => post.id, "commentId" => comment.id}, socket)
    refute Repo.get(Comment, comment.id)
  end

  test "does not delete a comment when not an authorized user", 
       %{post: post, comment: comment} do
    {:error, message} = CommentHelper.delete(%{"postId" => post.id, "commentId" => comment.id}, %{})
    assert message == "User is not authorized"
  end
end

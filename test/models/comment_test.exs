defmodule Pxblog.CommentTest do
  use Pxblog.ModelCase

  alias Pxblog.Comment
  import Pxblog.Factory

  @valid_attrs %{approved: true, body: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    user = insert(:user)
    post = insert(:post)
    changeset = Comment.changeset(%Comment{}, Map.merge(@valid_attrs, %{user_id: user.id, post_id: post.id}))
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Comment.changeset(%Comment{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "creates a comment associated with a post and an user" do
    comment = insert(:comment)
    assert comment.post_id
    assert comment.user_id
  end
end

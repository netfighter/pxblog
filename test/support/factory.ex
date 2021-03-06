defmodule Pxblog.Factory do
  use ExMachina.Ecto, repo: Pxblog.Repo

  alias Pxblog.Role
  alias Pxblog.User
  alias Pxblog.Post
  alias Pxblog.Comment

  def role_factory do
    %Role{
      name: sequence(:name, &"Test Role #{&1}"),
      admin: false
    }
  end

  def user_factory do
    %User{
      username: sequence(:username, &"User #{&1}"),
      email: sequence(:email, &"test#{&1}@test.com"),
      password: "test1234",
      password_confirmation: "test1234",
      encrypted_password: Comeonin.Bcrypt.hashpwsalt("test1234"),
      role: build(:role)
    }
  end

  def post_factory do
    %Post{
      title: "Some Post",
      body: "And the body of some post",
      user: build(:user)
    }
  end

  def comment_factory do
    %Comment{
      user: build(:user),
      body: "This is a sample comment",
      post: build(:post)
    }
  end
end

defmodule Pxblog.UserTest do
  use Pxblog.ModelCase

  alias Pxblog.User
  import Pxblog.Factory

  @valid_attrs %{email: "some content", password: "test1234", password_confirmation: "test1234", username: "some content"}
  @invalid_attrs %{}

  defp valid_attrs(role) do
    Map.put(@valid_attrs, :role_id, role.id)
  end
  
  setup do
    role = insert(:role)
    {:ok, role: role}
  end

  test "changeset with valid attributes", %{role: role} do
    changeset = User.changeset(%User{}, valid_attrs(role))
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "encrypted_password value gets set to a hash", %{role: role} do
    attrs = valid_attrs(role)
    changeset = User.changeset_with_password(%User{}, attrs)
    assert Comeonin.Bcrypt.checkpw(attrs.password, Ecto.Changeset.get_change(changeset, :encrypted_password))
  end

  test "encrypted_password value does not get set if password is nil" do
    changeset = User.changeset(%User{}, %{email: "test@test.com", password: nil, password_confirmation: nil, username: "test"})
    refute Ecto.Changeset.get_change(changeset, :encrypted_password)
  end
end

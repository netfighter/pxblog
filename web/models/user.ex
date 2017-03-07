defmodule Pxblog.User do
  use Pxblog.Web, :model
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]
  alias Pxblog.Repo

  schema "users" do
    has_many :posts, Pxblog.Post
    has_many :comments, Pxblog.Comment
    belongs_to :role, Pxblog.Role
    
    field :username, :string
    field :email, :string
    field :encrypted_password, :string
    field :reset_password_token, :string
    field :reset_password_sent_at, :naive_datetime

    timestamps()

    # Virtual Fields
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true  
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :email, :password, :password_confirmation, :role_id, :reset_password_token, :reset_password_sent_at])
    |> validate_required([:username, :email, :role_id])
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  @doc """
  Builds a changeset, including password validations, based on the `struct` and `params`.
  """
  def changeset_with_password(struct, params \\ %{}) do
    changeset(struct, params)
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password, message: "does not match password!")
    |> hash_password
  end
  
  defp hash_password(changeset) do
    if password = get_change(changeset, :password) do
      changeset
      |> put_change(:encrypted_password, hashpwsalt(password))
    else
      changeset
    end
  end
end

defmodule Pxblog.Comment do
  use Pxblog.Web, :model

  schema "comments" do
    field :body, :string
    belongs_to :post, Pxblog.Post
    belongs_to :user, Pxblog.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body, :post_id, :user_id])
    |> validate_required([:body, :post_id, :user_id])
  end
end

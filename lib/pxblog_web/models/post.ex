defmodule Pxblog.Post do
  use Pxblog.Web, :model
  alias Phoenix.HTML

  schema "posts" do
    belongs_to :user, Pxblog.User
    has_many :comments, Pxblog.Comment

    field :title, :string
    field :body, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body])
    |> validate_required([:title, :body])
    |> strip_unsafe_body(params)
  end

  defp strip_unsafe_body(model, %{"body" => nil}) do
    model
  end

  defp strip_unsafe_body(model, %{"body" => body}) do
    {:safe, clean_body} = HTML.html_escape(body)
    model |> put_change(:body, clean_body)
  end

  defp strip_unsafe_body(model, _) do
    model
  end
end

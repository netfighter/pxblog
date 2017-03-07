defmodule Pxblog.Repo.Migrations.RemoveAuthorFromComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      remove :author
    end
  end
end

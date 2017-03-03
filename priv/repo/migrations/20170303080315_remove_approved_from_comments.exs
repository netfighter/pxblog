defmodule Pxblog.Repo.Migrations.RemoveApprovedFromComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      remove :approved
    end
  end
end

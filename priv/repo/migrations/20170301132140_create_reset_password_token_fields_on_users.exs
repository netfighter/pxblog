defmodule Pxblog.Repo.Migrations.CreateResetPasswordTokenFieldsOnUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :reset_password_token, :string
      add :reset_password_sent_at, :naive_datetime
    end
  end
end

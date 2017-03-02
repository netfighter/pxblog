defmodule Pxblog.Repo.Migrations.UsersRenamePasswordField do
  use Ecto.Migration

  def change do
    rename table(:users), :password_digest, to: :encrypted_password
  end
end

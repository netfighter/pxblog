alias Pxblog.Repo
alias Pxblog.Role
alias Pxblog.User
import Ecto.Query, only: [from: 2]

find_or_create_role = fn role_name, admin ->
  case Repo.all(from r in Role, where: r.name == ^role_name and r.admin == ^admin) do
    [] ->
      %Role{}
      |> Role.changeset(%{name: role_name, admin: admin})
      |> Repo.insert!()
    roles ->
      IO.puts "Role: #{role_name} already exists, skipping"
      List.first(roles)
  end
end

find_or_create_user = fn username, email, role ->
  case Repo.all(from u in User, where: u.username == ^username and u.email == ^email) do
    [] ->
      %User{}
      |> User.changeset_with_password(%{username: username, email: email, password: "test1234", password_confirmation: "test1234", role_id: role.id})
      |> Repo.insert!()
    users ->
      IO.puts "User: #{username} already exists, skipping"
      List.first(users)
  end
end

user_role = find_or_create_role.("User Role", false)
admin_role = find_or_create_role.("Admin Role", true)
_admin = find_or_create_user.("Admin", "admin@test.com", admin_role)
_user = find_or_create_user.("User", "user@test.com", user_role)

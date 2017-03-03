defmodule Pxblog.ControllerHelpers do
  alias Pxblog.User

  defp get_user(user_id) do
    Repo.get!(User, user_id)
  end

  defp current_user(conn) do
    get_session(conn, :current_user)
  end
end
defmodule Pxblog.Plugs.AssignUser do
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  alias Pxblog.Repo
  alias Pxblog.User 
  alias Pxblog.Role

  def init(default), do: default

  def call(conn, _) do
    user = case get_session(conn, :current_user) do
      %{id: user_id} -> 
        Repo.one from u in User, where: u.id == ^user_id, preload: [:role]
      _ -> 
        nil
    end
    
    conn |> Plug.Conn.assign(:current_user, user)
  end
end

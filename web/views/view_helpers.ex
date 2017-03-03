defmodule Pxblog.ViewHelpers do
  use Timex

  def format_date(date) do
    Timex.format!(date, "%Y-%m-%d %H:%M", :strftime)
  end

  def allowed_to_delete_comment?(conn, comment) do
    (user = current_user(conn)) && (user.admin || user.id == comment.user_id)
  end

  def current_user(conn) do
    Plug.Conn.get_session(conn, :current_user)
  end
end

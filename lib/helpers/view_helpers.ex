defmodule Pxblog.Helpers.ViewHelpers do
  use Timex

  def format_date(date) do
    Timex.format!(date, "%Y-%m-%d %H:%M", :strftime)
  end

  def current_user(conn) do
    Plug.Conn.get_session(conn, :current_user)
  end
end

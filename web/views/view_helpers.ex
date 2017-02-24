defmodule Pxblog.ViewHelpers do
  use Timex

  def format_date(date) do
    Timex.format!(date, "%Y-%m-%d %H:%M", :strftime)
  end
end

defmodule PxblogWeb.PostView do
  use Pxblog.Web, :view

  def markdown(body) do
    {:safe, Earmark.as_html!(body)} |> raw
  end
end

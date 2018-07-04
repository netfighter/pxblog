defmodule PxblogWeb.PostViewTest do
  use PxblogWeb.ConnCase, async: true

  test "converts markdown to html" do
    {:safe, result} = PxblogWeb.PostView.markdown("**bold me**")
    assert String.contains? result, "<strong>bold me</strong>"
  end

  test "leaves text with no markdown alone" do
    {:safe, result} = PxblogWeb.PostView.markdown("leave me alone")
    assert String.contains? result, "leave me alone"
  end
end

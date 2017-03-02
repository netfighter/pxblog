defmodule Pxblog.UserEmail do
  use Phoenix.Swoosh, view: Pxblog.EmailView, layout: {Pxblog.LayoutView, :email}
  @from "noreply@pxblog.com"

  def send_reset_password_email(user, reset_password_url) do
    new
    |> from({"Tiny Blog", @from})
    |> to(user.email)
    |> subject("Tiny Blog reset password instructions")
    |> render_body("reset_password_instructions.html", %{username: user.username, reset_password_url: reset_password_url})
  end
end

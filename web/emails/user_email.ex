defmodule Pxblog.UserEmail do
  use Phoenix.Swoosh, view: Pxblog.EmailView, layout: {Pxblog.LayoutView, :email}
  @from "noreply@pxblog.com"

  def send_welcome_email(user, sign_in_url) do
    new
    |> from({"Tiny Blog", @from})
    |> to(user.email)
    |> subject("Welcome to Tiny Blog!")
    |> render_body("welcome.html", %{username: user.username, sign_in_url: sign_in_url})
  end

  def send_reset_password_email(user, reset_password_url) do
    new
    |> from({"Tiny Blog", @from})
    |> to(user.email)
    |> subject("Tiny Blog reset password instructions")
    |> render_body("reset_password_instructions.html", %{username: user.username, reset_password_url: reset_password_url})
  end
end

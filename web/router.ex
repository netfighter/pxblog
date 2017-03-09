defmodule Pxblog.Router do
  use Pxblog.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Pxblog.Plugs.AssignUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Pxblog do
    pipe_through :browser # Use the default browser stack

    get "/", PostController, :index
    resources "/posts", PostController do
      resources "/comments", CommentController, only: [:create, :delete, :update]
    end
    get "/page", PageController, :index
    resources "/users", UserController, only: [:index, :new, :create, :edit, :update, :delete]
    get "/account/recover_password", AccountController, :recover_password, as: :recover_password
    post "/account/recover_password", AccountController, :recover_password, as: :recover_password
    get "/account/reset_password", AccountController, :reset_password, as: :reset_password
    put "/account/reset_password", AccountController, :reset_password, as: :reset_password
    resources "/account", AccountController, only: [:new, :create, :edit, :update, :delete] 
    resources "/sessions", SessionController, only: [:new, :create, :delete]
  end

  #if Mix.env == :dev do
  scope "/dev" do
    pipe_through [:browser]

    forward "/mailbox", Plug.Swoosh.MailboxPreview, [base_path: "/dev/mailbox"]
  end
  #end

  # Other scopes may use custom stacks.
  # scope "/api", Pxblog do
  #   pipe_through :api
  # end
end

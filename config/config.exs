# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :pxblog,
  ecto_repos: [Pxblog.Repo]

# Configures the endpoint
config :pxblog, PxblogWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yHTjYk/tna3o6mYgdYEfn5+EsGUl4OVujrsfBbHCJAv8MGnpFpuWBx444cG4NSiL",
  render_errors: [view: PxblogWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Pxblog.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine

config :canary, repo: Pxblog.Repo
config :canary, unauthorized_handler: {PxblogWeb.Helpers.AuthorizationHelpers, :handle_unauthorized}
config :canary, not_found_handler: {PxblogWeb.Helpers.AuthorizationHelpers, :handle_not_found}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

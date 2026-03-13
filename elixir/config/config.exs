import Config

# General configuration
config :phoenix, :json_library, Jason

# Symphony application configuration
config :symphony_elixir,
  generators: [timestamp_type: :utc_datetime]

# Web endpoint configuration
config :symphony_elixir, SymphonyElixirWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost", port: 4000],
  render_errors: [
    formats: [html: SymphonyElixirWeb.ErrorHTML, json: SymphonyElixirWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SymphonyElixir.PubSub,
  live_view: [signing_salt: "symphony-live-view-salt"],
  # Use environment variable for secret_key_base in production
  secret_key_base: System.get_env("SECRET_KEY_BASE") || String.duplicate("s", 64),
  check_origin: false,
  server: false

# Import environment-specific overrides
import_config "#{config_env()}.exs"

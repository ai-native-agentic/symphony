import Config

# Production environment configuration
# - Optimized for performance and security
# - Requires environment variables for sensitive data

# Get secret_key_base from environment or generate from file
secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    Generate one using: mix phx.gen.secret
    """

# Configure web endpoint for production
config :symphony_elixir, SymphonyElixirWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4000")
  ],
  url: [
    host: System.get_env("PHX_HOST") || "localhost",
    port: String.to_integer(System.get_env("PORT") || "4000")
  ],
  secret_key_base: secret_key_base,
  server: true,
  check_origin: ~r/^https?:\/\/.*$/,
  code_reloader: false,
  debug_errors: false

# Production logger configuration
config :logger,
  level: :info,
  handle_sasl_reports: false,
  handle_otp_reports: false

# Production application config
config :symphony_elixir,
  linear_api_key:
    System.get_env("LINEAR_API_KEY") ||
      raise "environment variable LINEAR_API_KEY is missing",
  codex_path: System.get_env("CODEX_PATH") || "codex",
  workspace_dir: System.get_env("SYMPHONY_WORKSPACE") || "./workspace"

# Bandit configuration for production
config :bandit,
  http: [
    transport_options: [
      socket_options: [:binary, {:reuseaddr, true}, {:keepalive, true}]
    ]
  ]

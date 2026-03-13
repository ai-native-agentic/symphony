import Config

# Test environment configuration
# - Disables code reloading for faster test execution
# - Uses test-specific database and storage

# Configure web endpoint for tests
config :symphony_elixir, SymphonyElixirWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  server: false,
  check_origin: false

# Disable Phoenix features not needed in tests
config :phoenix, :plug_init_mode, :runtime

# Logger configuration for tests (minimal output)
config :logger, level: :warning

# Test-specific application config
config :symphony_elixir,
  linear_api_key: System.get_env("LINEAR_API_KEY_TEST") || "test-key",
  codex_path: System.get_env("CODEX_PATH") || "codex"

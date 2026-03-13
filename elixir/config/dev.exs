import Config

# Development environment configuration
# - Enables code reloading and debugging features
# - Uses in-memory storage for faster development

# Configure web endpoint for development
config :symphony_elixir, SymphonyElixirWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  server: true,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:symphony, ~w(--sourcemap=inline --watch)]}
  ]

# Enable Phoenix LiveReload in development
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

# Logger configuration for development
config :logger, :console,
  format: "[$level] $message\n",
  level: :debug,
  metadata_keys: [:request_id]

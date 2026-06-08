import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :guitar_vault, GuitarVault.Repo,
  database: Path.expand("../guitar_vault_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :guitar_vault, GuitarVaultWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qTlY4xmpH9l1EfR2IB8v+tJ1K75vTRa8sFE5HxV4Ex8zzYCCZ3eJkZADfb95T+cT",
  server: false

# In test we don't send emails
config :guitar_vault, GuitarVault.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Store uploads in a throwaway tmp dir during tests
config :guitar_vault, :uploads_dir, Path.join(System.tmp_dir!(), "guitar_vault_test_uploads")

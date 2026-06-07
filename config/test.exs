import Config

config :pingbase, Pingbase.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "pingbase_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  ssl: false

config :pingbase, PingbaseWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "this-is-a-test-secret-key-base-that-needs-to-be-at-least-64-characters-long",
  server: false

config :pingbase, Pingbase.Mailer, adapter: Swoosh.Adapters.Test

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

import Config

config :pingbase, Pingbase.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "pingbase_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :pingbase, PingbaseWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev-secret-key-base-change-in-production",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:pingbase, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:pingbase, ~w(--watch)]}
  ]

config :pingbase, PingbaseWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/pingbase_web/(controllers|live|components)/.*(ex|heex)$}
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :swoosh, :api_client, Swoosh.ApiClient.Finch

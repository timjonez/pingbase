import Config

if config_env() == :prod do
  config :pingbase, Pingbase.Repo,
    url: System.get_env("DATABASE_URL"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true

  config :pingbase, PingbaseWeb.Endpoint,
    url: [host: System.get_env("PHX_HOST") || "example.com", port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
    secret_key_base: System.get_env("SECRET_KEY_BASE"),
    server: true

  config :pingbase, Pingbase.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: System.get_env("SMTP_RELAY"),
    username: System.get_env("SMTP_USERNAME"),
    password: System.get_env("SMTP_PASSWORD"),
    ssl: true,
    tls: :always,
    auth: :always,
    port: 587

  config :logger, level: :info
end

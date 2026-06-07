# This file is responsible for loading your configuration
import Config

config :pingbase,
  ecto_repos: [Pingbase.Repo],
  generators: [timestamp_type: :utc_datetime],
  env: config_env()

config :pingbase, PingbaseWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PingbaseWeb.ErrorHTML, json: PingbaseWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Pingbase.PubSub,
  live_view: [signing_salt: "a-very-long-live-view-signing-salt-for-pingbase-app"],
  secret_key_base: "this-is-a-development-secret-key-base-that-needs-to-be-at-least-64-characters-long"

config :pingbase, Pingbase.Mailer, adapter: Swoosh.Adapters.Local

config :esbuild,
  version: "0.17.11",
  pingbase: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.0",
  pingbase: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"

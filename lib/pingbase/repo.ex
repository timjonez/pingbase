defmodule Pingbase.Repo do
  use Ecto.Repo,
    otp_app: :pingbase,
    adapter: Ecto.Adapters.Postgres
end

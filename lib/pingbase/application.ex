defmodule Pingbase.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PingbaseWeb.Telemetry,
      Pingbase.Repo,
      {DNSCluster, query: Application.get_env(:pingbase, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pingbase.PubSub},
      {Finch, name: Pingbase.Finch},
      PingbaseWeb.Presence,
      PingbaseWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Pingbase.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PingbaseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

defmodule PingbaseWeb.Router do
  use PingbaseWeb, :router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PingbaseWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug PingbaseWeb.APIAuthPlug
  end

  scope "/", PingbaseWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/w", PingbaseWeb do
    pipe_through :browser

    live "/:workspace_slug", WorkspaceLive.Show, :show
    live "/:workspace_slug/rooms/:room_id", RoomLive.Show, :show
  end

  scope "/api", PingbaseWeb do
    pipe_through :api

    post "/webhooks/incoming/:token", WebhookController, :incoming
    post "/commands/:command_id", WebhookController, :slash_command
  end

  if Application.compile_env(:pingbase, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PingbaseWeb.Telemetry
    end
  end
end

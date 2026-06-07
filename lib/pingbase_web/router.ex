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
    get "/get-started", PageController, :get_started
    get "/join/:token", JoinController, :show
    live "/sign-in", SignInLive, :index
    get "/sign-in/verify", SignInController, :verify
    get "/sign-out", SignOutController, :sign_out
  end

  scope "/onboarding", PingbaseWeb do
    pipe_through :browser

    get "/verify", OnboardingController, :verify
    live "/", OnboardingLive.Index, :index
    live "/:step", OnboardingLive.Index, :index
  end

  scope "/settings", PingbaseWeb do
    pipe_through :browser

    live "/profile", SettingsLive.Profile, :profile
    live "/tokens", SettingsLive.Tokens, :tokens
  end

  scope "/w", PingbaseWeb do
    pipe_through :browser

    live "/:workspace_slug", WorkspaceLive.Show, :show
    live "/:workspace_slug/rooms/:room_id", RoomLive.Show, :show
    live "/:workspace_slug/settings/general", WorkspaceSettingsLive.General, :general
    live "/:workspace_slug/settings/members", WorkspaceSettingsLive.Members, :members
    live "/:workspace_slug/settings/notifications", WorkspaceSettingsLive.Notifications, :notifications
    live "/:workspace_slug/settings/billing", WorkspaceSettingsLive.Billing, :billing
    live "/:workspace_slug/settings/integrations", WorkspaceSettingsLive.Integrations, :integrations
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
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

defmodule PingbaseWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use PingbaseWeb, :controller
      use PingbaseWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and focused on imports,
  uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those in here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: PingbaseWeb.Layouts]

      import Plug.Conn

      alias PingbaseWeb.Router.Helpers, as: Routes
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PingbaseWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form

      import PingbaseWeb.CoreComponents
      import PingbaseWeb.Gettext

      use Phoenix.VerifiedRoutes,
        endpoint: PingbaseWeb.Endpoint,
        router: PingbaseWeb.Router,
        statics: PingbaseWeb.static_paths()

      alias Phoenix.LiveView.JS
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PingbaseWeb.Endpoint,
        router: PingbaseWeb.Router,
        statics: PingbaseWeb.static_paths()
    end
  end

  def json do
    quote do
      use Phoenix.Controller,
        formats: [:json],
        layouts: false

      alias PingbaseWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

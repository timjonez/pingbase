defmodule PingbaseWeb.PageController do
  use PingbaseWeb, :controller

  alias Pingbase.Demo
  alias Pingbase.Accounts

  def home(conn, _params) do
    render(conn, :home)
  end

  def get_started(conn, _params) do
    workspace = Demo.ensure_workspace()
    room = Demo.get_demo_room(workspace)
    demo_user = Accounts.get_user_by_email("demo@pingbase.local")

    conn
    |> put_session(:user_id, demo_user.id)
    |> redirect(to: "/w/#{workspace.slug}/rooms/#{room.id}")
  end
end

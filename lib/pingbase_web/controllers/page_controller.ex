defmodule PingbaseWeb.PageController do
  use PingbaseWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

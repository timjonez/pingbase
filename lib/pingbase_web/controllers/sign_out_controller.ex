defmodule PingbaseWeb.SignOutController do
  @moduledoc """
  Handles sign-out by clearing the session.
  """
  use PingbaseWeb, :controller

  def sign_out(conn, _params) do
    conn
    |> delete_session(:user_id)
    |> configure_session(drop: true)
    |> put_flash(:info, "Signed out successfully.")
    |> redirect(to: "/")
  end
end

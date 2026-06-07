defmodule PingbaseWeb.SignInController do
  @moduledoc """
  Handles magic link verification for sign-in.
  """
  use PingbaseWeb, :controller

  alias Pingbase.Accounts.MagicLink
  alias Pingbase.Workspaces

  def verify(conn, %{"token" => token}) do
    case MagicLink.verify_token(token) do
      {:ok, user} ->
        conn = put_session(conn, :user_id, user.id)

        workspaces = Workspaces.list_user_workspaces(user)

        case workspaces do
          [] ->
            conn
            |> put_flash(:info, "Welcome! Let's create your workspace.")
            |> redirect(to: "/onboarding/workspace")

          [workspace | _] ->
            conn
            |> put_flash(:info, "Welcome back!")
            |> redirect(to: "/w/#{workspace.slug}")
        end

      :error ->
        conn
        |> put_flash(:error, "Invalid or expired link. Please try again.")
        |> redirect(to: "/sign-in")
    end
  end
end

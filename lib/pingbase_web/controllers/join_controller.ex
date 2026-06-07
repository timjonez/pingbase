defmodule PingbaseWeb.JoinController do
  use PingbaseWeb, :controller

  alias Pingbase.Accounts
  alias Pingbase.Workspaces

  def show(conn, %{"token" => token}) do
    case Workspaces.get_invite_by_token(token) do
      nil ->
        conn
        |> put_flash(:error, "This invite is invalid or has expired.")
        |> redirect(to: "/")

      invite ->
        case get_session(conn, :user_id) do
          nil ->
            conn
            |> redirect(to: "/onboarding/auth?invite=#{token}")

          user_id ->
            user = Accounts.get_user!(user_id)

            case Workspaces.accept_invite(invite, user) do
              {:ok, _membership} ->
                conn
                |> put_flash(:info, "Welcome to #{invite.workspace.name}!")
                |> redirect(to: "/w/#{invite.workspace.slug}")

              {:error, _reason} ->
                conn
                |> put_flash(:error, "Failed to accept the invite.")
                |> redirect(to: "/")
            end
        end
    end
  end
end

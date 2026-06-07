defmodule PingbaseWeb.OnboardingController do
  use PingbaseWeb, :controller

  alias Pingbase.Accounts.MagicLink
  alias Pingbase.Workspaces

  def verify(conn, %{"token" => token} = params) do
    case MagicLink.verify_token(token) do
      {:ok, user} ->
        conn = put_session(conn, :user_id, user.id)

        case params["invite"] do
          nil ->
            conn
            |> put_flash(:info, "Welcome! Let's create your workspace.")
            |> redirect(to: "/onboarding/workspace")

          invite_token ->
            case Workspaces.get_invite_by_token(invite_token) do
              nil ->
                conn
                |> put_flash(:error, "Invalid or expired invite.")
                |> redirect(to: "/onboarding/workspace")

              invite ->
                case Workspaces.accept_invite(invite, user) do
                  {:ok, _} ->
                    conn
                    |> put_flash(:info, "Welcome to #{invite.workspace.name}!")
                    |> redirect(to: "/w/#{invite.workspace.slug}")

                  {:error, _reason} ->
                    conn
                    |> put_flash(:error, "Failed to accept the invite.")
                    |> redirect(to: "/onboarding/workspace")
                end
            end
        end

      :error ->
        conn
        |> put_flash(:error, "Invalid or expired link. Please try again.")
        |> redirect(to: "/onboarding/auth")
    end
  end
end

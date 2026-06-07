defmodule PingbaseWeb.WebhookController do
  use PingbaseWeb, :controller

  alias Pingbase.Integrations
  alias Pingbase.Chat

  def incoming(conn, %{"token" => token}) do
    case Integrations.get_incoming_webhook_by_token(token) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})

      webhook ->
        message = conn.body_params["text"] || ""
        username = conn.body_params["username"] || webhook.name

        Chat.create_message(%{
          room_id: webhook.room_id,
          user_id: webhook.workspace_id,
          content: "**#{username}**: #{message}"
        })

        conn
        |> put_status(:ok)
        |> json(%{ok: true})
    end
  end

  def slash_command(conn, %{"command_id" => _command_id}) do
    # TODO: Implement slash command handling
    conn
    |> put_status(:ok)
    |> json(%{text: "Command received"})
  end
end

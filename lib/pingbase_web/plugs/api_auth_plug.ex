defmodule PingbaseWeb.APIAuthPlug do
  @moduledoc """
  Plug for authenticating API requests using bearer tokens.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Token " <> token] ->
        case Pingbase.Accounts.validate_api_token(token) do
          {:ok, user} ->
            assign(conn, :current_user, user)

          :error ->
            conn |> send_resp(401, "Unauthorized") |> halt()
        end

      _ ->
        conn |> send_resp(401, "Unauthorized") |> halt()
    end
  end
end

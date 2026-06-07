defmodule PingbaseWeb.UserAuth do
  @moduledoc """
  Authentication helpers for LiveViews.
  """
  import Phoenix.Component, only: [assign: 2]
  alias Pingbase.Accounts

  def on_mount(:default, _params, session, socket) do
    case session do
      %{"user_id" => user_id} ->
        user = Accounts.get_user!(user_id)
        {:cont, assign(socket, current_user: user)}

      _ ->
        {:cont, assign(socket, current_user: nil)}
    end
  end

  def on_mount(:require_user, _params, session, socket) do
    case session do
      %{"user_id" => user_id} ->
        user = Accounts.get_user!(user_id)
        {:cont, assign(socket, current_user: user)}

      _ ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, "You must be signed in to access this page.")
          |> Phoenix.LiveView.redirect(to: "/sign-in")

        {:halt, socket}
    end
  end

  def on_mount(:require_guest, _params, session, socket) do
    case session do
      %{"user_id" => user_id} ->
        user = Accounts.get_user!(user_id)

        socket =
          socket
          |> Phoenix.LiveView.put_flash(:info, "You are already signed in.")
          |> Phoenix.LiveView.redirect(to: "/")

        {:halt, socket}

      _ ->
        {:cont, assign(socket, current_user: nil)}
    end
  end
end

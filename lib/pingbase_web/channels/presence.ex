defmodule PingbaseWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and live views.

  This uses `Phoenix.Presence` to track which users are online
  in which workspaces and rooms.
  """
  use Phoenix.Presence,
    otp_app: :pingbase,
    pubsub_server: Pingbase.PubSub
end

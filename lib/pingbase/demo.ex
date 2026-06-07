defmodule Pingbase.Demo do
  @moduledoc """
  Creates and manages a demo workspace for first-time visitors.
  """

  alias Pingbase.Accounts
  alias Pingbase.Workspaces
  alias Pingbase.Chat

  @demo_slug "demo"
  @demo_user_email "demo@pingbase.local"

  def ensure_workspace do
    case Workspaces.get_workspace_by_slug(@demo_slug) do
      nil -> create_demo_workspace()
      workspace -> workspace
    end
  end

  def get_demo_room(workspace) do
    rooms = Chat.list_rooms(workspace)

    case rooms do
      [] -> create_demo_room(workspace)
      [room | _] -> room
    end
  end

  defp create_demo_workspace do
    user =
      case Accounts.get_user_by_email(@demo_user_email) do
        nil ->
          {:ok, user} = Accounts.create_user(%{email: @demo_user_email, name: "Demo User"})
          user

        user ->
          user
      end

    {:ok, workspace} =
      Workspaces.create_workspace(user, %{
        slug: @demo_slug,
        name: "Demo Workspace",
        description: "A demo workspace to explore Pingbase."
      })

    create_demo_room(workspace)
    workspace
  end

  defp create_demo_room(workspace) do
    {:ok, room} =
      Chat.create_room(%{
        workspace_id: workspace.id,
        name: "general",
        slug: "general",
        type: "channel",
        topic: "Welcome to Pingbase!"
      })

    user = Accounts.get_user_by_email(@demo_user_email)

    {:ok, _message} =
      Chat.create_message(%{
        room_id: room.id,
        user_id: user.id,
        content: "Welcome to Pingbase! This is a demo workspace. Try sending a message or replying in a thread."
      })

    room
  end
end

defmodule Pingbase.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pingbase.Chat` context.
  """

  alias Pingbase.Chat
  alias Pingbase.AccountsFixtures
  alias Pingbase.WorkspacesFixtures

  def room_fixture(workspace, attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        name: "room-#{System.unique_integer()}",
        slug: "room-#{System.unique_integer()}",
        workspace_id: workspace.id,
        type: "channel"
      })
      |> Chat.create_room()

    room
  end

  def message_fixture(room, attrs \\ %{}) do
    user = attrs[:user] || AccountsFixtures.user_fixture()

    {:ok, message} =
      attrs
      |> Enum.into(%{
        content: "Test message",
        room_id: room.id,
        user_id: user.id
      })
      |> Chat.create_message()

    message
  end

  def thread_reply_fixture(parent_message, attrs \\ %{}) do
    user = attrs[:user] || AccountsFixtures.user_fixture()

    {:ok, reply} =
      attrs
      |> Enum.into(%{
        content: "Thread reply",
        room_id: parent_message.room_id,
        user_id: user.id,
        parent_id: parent_message.id
      })
      |> Chat.create_message()

    reply
  end
end

defmodule Pingbase.ChatTest do
  use Pingbase.DataCase

  alias Pingbase.Chat

  describe "rooms" do
    alias Pingbase.Chat.Room

    import Pingbase.AccountsFixtures
    import Pingbase.WorkspacesFixtures

    @invalid_attrs %{name: nil, slug: nil, workspace_id: nil}

    test "list_rooms/1 returns rooms for a workspace" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      rooms = Chat.list_rooms(workspace)
      assert length(rooms) >= 1
    end

    test "get_room!/1 returns the room with given id" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      assert Chat.get_room!(room.id).id == room.id
    end

    test "create_room/1 with valid data creates a room" do
      workspace = workspace_fixture()
      valid_attrs = %{name: "general", slug: "general", workspace_id: workspace.id}

      assert {:ok, %Room{} = room} = Chat.create_room(valid_attrs)
      assert room.name == "general"
      assert room.slug == "general"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_room(@invalid_attrs)
    end

    test "archive_room/1 archives the room" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      assert {:ok, %Room{} = room} = Chat.archive_room(room)
      assert room.is_archived == true
    end
  end

  describe "messages" do
    alias Pingbase.Chat.Message

    import Pingbase.AccountsFixtures
    import Pingbase.WorkspacesFixtures

    test "list_messages/1 returns messages for a room" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      message = message_fixture(room)
      messages = Chat.list_messages(room)
      assert length(messages) >= 1
    end

    test "create_message/1 with valid data creates a message" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      user = user_fixture()

      valid_attrs = %{content: "Hello world", room_id: room.id, user_id: user.id}

      assert {:ok, %Message{} = message} = Chat.create_message(valid_attrs)
      assert message.content == "Hello world"
    end
  end

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
    user = attrs[:user] || user_fixture()

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
end

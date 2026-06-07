defmodule Pingbase.ChatTest do
  use Pingbase.DataCase

  alias Pingbase.Chat
  alias Pingbase.Notifications

  import Pingbase.AccountsFixtures
  import Pingbase.WorkspacesFixtures
  import Pingbase.ChatFixtures

  describe "rooms" do
    alias Pingbase.Chat.Room

    @invalid_attrs %{name: nil, slug: nil, workspace_id: nil}

    test "list_rooms/1 returns rooms for a workspace" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      rooms = Chat.list_rooms(workspace)
      assert length(rooms) >= 1
      assert room.id in Enum.map(rooms, & &1.id)
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
      assert room.type == "channel"
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

    test "list_messages/1 returns messages for a room" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      message = message_fixture(room)
      messages = Chat.list_messages(room)
      assert length(messages) >= 1
      assert message.id in Enum.map(messages, & &1.id)
    end

    test "list_messages/2 paginates with before_id" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      msg1 = message_fixture(room)
      msg2 = message_fixture(room)

      messages = Chat.list_messages(room, limit: 1)
      assert length(messages) == 1

      messages = Chat.list_messages(room, before_id: max(msg1.id, msg2.id) + 1, limit: 50)
      assert length(messages) == 2
    end

    test "create_message/1 with valid data creates a message" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      user = user_fixture()

      valid_attrs = %{content: "Hello world", room_id: room.id, user_id: user.id}

      assert {:ok, %Message{} = message} = Chat.create_message(valid_attrs)
      assert message.content == "Hello world"
    end

    test "send_message/3 creates a message and parses mentions" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      sender = user_fixture(%{name: "Sender"})
      mentioned = user_fixture(%{name: "Mentioned"})

      # Add mentioned user to workspace
      Pingbase.Workspaces.add_member(workspace, mentioned)

      {:ok, message} = Chat.send_message(room, sender, %{"content" => "Hey @Mentioned, how are you?"})
      assert message.content == "Hey @Mentioned, how are you?"

      # Check that a mention was created
      message = Chat.get_message!(message.id)
      assert length(message.mentions) == 1
      assert hd(message.mentions).mentioned_user_id == mentioned.id

      # Check that a notification was created
      assert Notifications.unread_count(mentioned) == 1
    end

    test "send_message/3 with no mentions does not create notifications" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      sender = user_fixture()

      {:ok, _message} = Chat.send_message(room, sender, %{"content" => "Hello everyone"})
      assert Notifications.unread_count(sender) == 0
    end

    test "update_message/2 updates the message" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      message = message_fixture(room)

      assert {:ok, %Message{} = message} = Chat.update_message(message, %{"content" => "Updated"})
      assert message.content == "Updated"
    end

    test "delete_message/1 deletes the message" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      message = message_fixture(room)

      assert {:ok, %Message{}} = Chat.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(message.id) end
    end
  end

  describe "thread messages" do
    test "list_thread_messages/1 returns replies for a message" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      parent = message_fixture(room)
      reply = thread_reply_fixture(parent)

      thread_messages = Chat.list_thread_messages(parent)
      assert length(thread_messages) == 1
      assert hd(thread_messages).id == reply.id
    end
  end

  describe "reactions" do
    test "add_reaction/3 adds a reaction to a message" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      message = message_fixture(room)
      user = user_fixture()

      assert {:ok, _reaction} = Chat.add_reaction(message, user, "👍")

      message = Chat.get_message!(message.id)
      assert length(message.reactions) == 1
      assert hd(message.reactions).emoji == "👍"
    end

    test "remove_reaction/3 removes a reaction from a message" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      message = message_fixture(room)
      user = user_fixture()

      {:ok, _reaction} = Chat.add_reaction(message, user, "👍")
      assert {:ok, _reaction} = Chat.remove_reaction(message, user, "👍")

      message = Chat.get_message!(message.id)
      assert message.reactions == []
    end
  end

  describe "mentions" do
    test "parse_mentions/1 finds users by name" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      mentioned = user_fixture(%{name: "Alice"})
      Pingbase.Workspaces.add_member(workspace, mentioned)

      message = %Pingbase.Chat.Message{
        content: "Hey @Alice, how are you?",
        room_id: room.id
      }

      users = Chat.parse_mentions(message)
      assert length(users) == 1
      assert hd(users).id == mentioned.id
    end

    test "parse_mentions/1 finds users by display_name" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      mentioned = user_fixture(%{name: "Bob", display_name: "Bobby"})
      Pingbase.Workspaces.add_member(workspace, mentioned)

      message = %Pingbase.Chat.Message{
        content: "Hey @Bobby, how are you?",
        room_id: room.id
      }

      users = Chat.parse_mentions(message)
      assert length(users) == 1
      assert hd(users).id == mentioned.id
    end
  end

  describe "room memberships" do
    test "update_last_read/3 updates the last read message" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      user = user_fixture()
      message = message_fixture(room)

      assert {:ok, _} = Chat.update_last_read(room, user, message.id)
      assert Chat.get_last_read(room, user) == message.id
    end

    test "unread_count/2 counts unread messages" do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      user = user_fixture()

      # Initially all messages are unread
      message_fixture(room)
      assert Chat.unread_count(room, user) == 1

      # After reading, count is 0
      message = message_fixture(room)
      Chat.update_last_read(room, user, message.id)
      assert Chat.unread_count(room, user) == 0
    end
  end
end

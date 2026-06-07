defmodule Pingbase.Chat do
  @moduledoc """
  The Chat context.

  This context is responsible for managing rooms, messages,
  reactions, threads, attachments, and mentions.
  """

  import Ecto.Query, warn: false
  alias Pingbase.Repo

  alias Pingbase.Chat.Room
  alias Pingbase.Chat.RoomMembership
  alias Pingbase.Chat.Message
  alias Pingbase.Chat.MessageReaction
  alias Pingbase.Chat.MessageMention
  alias Pingbase.Chat.Attachment

  alias Pingbase.Workspaces.Workspace
  alias Pingbase.Accounts.User

  ## Rooms

  @doc """
  Returns the list of rooms for a workspace.
  """
  def list_rooms(%Workspace{} = workspace) do
    Room
    |> where(workspace_id: ^workspace.id)
    |> order_by([r], asc: r.type, asc: r.name)
    |> Repo.all()
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.
  """
  def get_room!(id), do: Repo.get!(Room, id)

  @doc """
  Creates a room.
  """
  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.
  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.
  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Archives a room.
  """
  def archive_room(%Room{} = room) do
    room
    |> Ecto.Changeset.change(is_archived: true)
    |> Repo.update()
  end

  ## Room Memberships

  @doc """
  Joins a user to a room.
  """
  def join_room(%Room{} = room, %User{} = user) do
    %RoomMembership{}
    |> RoomMembership.changeset(%{room_id: room.id, user_id: user.id})
    |> Repo.insert()
  end

  @doc """
  Leaves a room.
  """
  def leave_room(%Room{} = room, %User{} = user) do
    RoomMembership
    |> where(room_id: ^room.id, user_id: ^user.id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      membership -> Repo.delete(membership)
    end
  end

  @doc """
  Lists room memberships for a user.
  """
  def list_user_room_memberships(%User{} = user) do
    RoomMembership
    |> where(user_id: ^user.id)
    |> preload(:room)
    |> Repo.all()
  end

  @doc """
  Gets a room membership for a user.
  """
  def get_room_membership(%Room{} = room, %User{} = user) do
    RoomMembership
    |> where(room_id: ^room.id, user_id: ^user.id)
    |> Repo.one()
  end

  @doc """
  Updates a room membership's notification level.
  """
  def update_room_membership(%RoomMembership{} = membership, attrs) do
    membership
    |> RoomMembership.changeset(attrs)
    |> Repo.update()
  end

  ## Messages

  @doc """
  Returns messages for a room, paginated.
  """
  def list_messages(%Room{} = room, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    before_id = Keyword.get(opts, :before_id)

    messages =
      Message
      |> where(room_id: ^room.id)
      |> where([m], is_nil(m.parent_id))
      |> maybe_before_id(before_id)
      |> order_by(desc: :inserted_at)
      |> limit(^limit)
      |> preload([:user, :reactions, :attachments])
      |> Repo.all()

    message_ids = Enum.map(messages, & &1.id)

    reply_counts =
      Message
      |> where([m], m.parent_id in ^message_ids)
      |> group_by([m], m.parent_id)
      |> select([m], {m.parent_id, count(m.id)})
      |> Repo.all()
      |> Enum.into(%{})

    Enum.map(messages, fn message ->
      %{message | reply_count: Map.get(reply_counts, message.id, 0)}
    end)
  end

  defp maybe_before_id(query, nil), do: query
  defp maybe_before_id(query, before_id) do
    where(query, [m], m.id < ^before_id)
  end

  @doc """
  Gets a single message.
  """
  def get_message!(id) do
    Message
    |> Repo.get!(id)
    |> Repo.preload([:user, :reactions, :attachments, :mentions])
  end

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sends a message, parsing mentions and creating notifications.
  Also broadcasts the message to the room's PubSub topic.
  """
  def send_message(%Room{} = room, %User{} = user, attrs) do
    Repo.transaction(fn ->
      message_attrs = Map.merge(attrs, %{"room_id" => room.id, "user_id" => user.id})

      message =
        %Message{}
        |> Message.changeset(message_attrs)
        |> Repo.insert!()
        |> Repo.preload(:user)

      # Parse mentions and create notifications
      parse_mentions(message)
      |> Enum.each(fn user ->
        create_mention(message, user)
        Pingbase.Notifications.notify_mention(user, message)
      end)

      # Update last read for sender
      update_last_read(room, user, message.id)

      # Broadcast to room
      broadcast_message(message)

      # If thread reply, broadcast thread update
      if message.parent_id do
        broadcast_thread_reply(message)
      end

      message
    end)
  end

  @doc """
  Parses @mentions from message content and returns list of mentioned users.
  """
  def parse_mentions(%Message{content: content, room_id: room_id}) do
    # Regex matches @username or @display_name
    mention_pattern = ~r/@([a-zA-Z0-9_\-\.]+)/

    mentioned_names =
      Regex.scan(mention_pattern, content)
      |> Enum.map(fn [_, name] -> String.downcase(name) end)
      |> Enum.uniq()

    if mentioned_names == [] do
      []
    else
      # Find users in the same workspace by name or display_name
      room = get_room!(room_id) |> Repo.preload(:workspace)

      User
      |> join(:inner, [u], wm in Pingbase.Workspaces.WorkspaceMembership,
        on: wm.user_id == u.id and wm.workspace_id == ^room.workspace_id
      )
      |> where([u], fragment("LOWER(?) = ANY(?)", u.name, ^mentioned_names) or fragment("LOWER(?) = ANY(?)", u.display_name, ^mentioned_names))
      |> Repo.all()
    end
  end

  def parse_mentions(_), do: []

  @doc """
  Broadcasts a message to the room's PubSub topic.
  """
  def broadcast_message(%Message{} = message) do
    message = Repo.preload(message, [:user, :reactions, :attachments])
    Phoenix.PubSub.broadcast(Pingbase.PubSub, "room:#{message.room_id}", {:new_message, message})
  end

  @doc """
  Broadcasts a thread reply count update to the room's PubSub topic.
  """
  def broadcast_thread_reply(%Message{parent_id: parent_id, room_id: room_id}) do
    count =
      Message
      |> where(parent_id: ^parent_id)
      |> Repo.aggregate(:count, :id)

    Phoenix.PubSub.broadcast(
      Pingbase.PubSub,
      "room:#{room_id}",
      {:thread_reply, parent_id, count}
    )
  end

  @doc """
  Broadcasts a typing event to the room.
  """
  def broadcast_typing(%Room{} = room, %User{} = user) do
    Phoenix.PubSub.broadcast(
      Pingbase.PubSub,
      "room:#{room.id}:typing",
      {:typing, %{user_id: user.id, user_name: user.name}}
    )
  end

  @doc """
  Updates the last read message for a user in a room.
  """
  def update_last_read(%Room{} = room, %User{} = user, message_id) do
    RoomMembership
    |> where(room_id: ^room.id, user_id: ^user.id)
    |> Repo.one()
    |> case do
      nil ->
        %RoomMembership{}
        |> RoomMembership.changeset(%{
          room_id: room.id,
          user_id: user.id,
          last_read_message_id: message_id
        })
        |> Repo.insert()

      membership ->
        membership
        |> Ecto.Changeset.change(last_read_message_id: message_id)
        |> Repo.update()
    end
  end

  @doc """
  Returns the last read message id for a user in a room.
  """
  def get_last_read(%Room{} = room, %User{} = user) do
    RoomMembership
    |> where(room_id: ^room.id, user_id: ^user.id)
    |> select([rm], rm.last_read_message_id)
    |> Repo.one()
  end

  @doc """
  Counts unread messages for a user in a room.
  """
  def unread_count(%Room{} = room, %User{} = user) do
    last_read = get_last_read(room, user)

    query =
      Message
      |> where(room_id: ^room.id)
      |> where([m], is_nil(m.parent_id))

    query =
      if last_read do
        where(query, [m], m.id > ^last_read)
      else
        query
      end

    Repo.aggregate(query, :count, :id)
  end

  @doc """
  Updates a message.
  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.
  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  ## Thread Messages

  @doc """
  Returns thread replies for a message.
  """
  def list_thread_messages(%Message{} = message) do
    Message
    |> where(parent_id: ^message.id)
    |> order_by(:inserted_at)
    |> preload([:user, :reactions, :attachments])
    |> Repo.all()
  end

  ## Reactions

  @doc """
  Adds a reaction to a message.
  """
  def add_reaction(%Message{} = message, %User{} = user, emoji) do
    %MessageReaction{}
    |> MessageReaction.changeset(%{
      message_id: message.id,
      user_id: user.id,
      emoji: emoji
    })
    |> Repo.insert()
  end

  @doc """
  Removes a reaction from a message.
  """
  def remove_reaction(%Message{} = message, %User{} = user, emoji) do
    MessageReaction
    |> where(message_id: ^message.id, user_id: ^user.id, emoji: ^emoji)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      reaction -> Repo.delete(reaction)
    end
  end

  ## Mentions

  @doc """
  Creates a mention in a message.
  """
  def create_mention(%Message{} = message, %User{} = mentioned_user) do
    %MessageMention{}
    |> MessageMention.changeset(%{
      message_id: message.id,
      mentioned_user_id: mentioned_user.id
    })
    |> Repo.insert()
  end

  ## Attachments

  @doc """
  Creates an attachment.
  """
  def create_attachment(attrs \\ %{}) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert()
  end
end

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
    |> order_by([r], r.type, r.name)
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

  ## Messages

  @doc """
  Returns messages for a room, paginated.
  """
  def list_messages(%Room{} = room, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    before_id = Keyword.get(opts, :before_id)

    Message
    |> where(room_id: ^room.id)
    |> where([m], is_nil(m.parent_id))
    |> maybe_before_id(before_id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> preload([:user, :reactions, :attachments])
    |> Repo.all()
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

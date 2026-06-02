defmodule Pingbase.Notifications do
  @moduledoc """
  The Notifications context.

  This context is responsible for managing user notifications,
  unread counts, and digests.
  """

  import Ecto.Query, warn: false
  alias Pingbase.Repo

  alias Pingbase.Notifications.Notification
  alias Pingbase.Accounts.User

  @doc """
  Returns notifications for a user.
  """
  def list_user_notifications(%User{} = user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    only_unread = Keyword.get(opts, :only_unread, false)

    Notification
    |> where(user_id: ^user.id)
    |> maybe_unread(only_unread)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  defp maybe_unread(query, false), do: query
  defp maybe_unread(query, true) do
    where(query, [n], is_nil(n.read_at))
  end

  @doc """
  Returns the unread count for a user.
  """
  def unread_count(%User{} = user) do
    Notification
    |> where(user_id: ^user.id)
    |> where([n], is_nil(n.read_at))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Creates a notification.
  """
  def create_notification(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Marks a notification as read.
  """
  def mark_as_read(%Notification{} = notification) do
    notification
    |> Ecto.Changeset.change(read_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update()
  end

  @doc """
  Marks all notifications as read for a user.
  """
  def mark_all_as_read(%User{} = user) do
    Notification
    |> where(user_id: ^user.id)
    |> where([n], is_nil(n.read_at))
    |> Repo.update_all(set: [read_at: DateTime.utc_now() |> DateTime.truncate(:second)])
  end

  @doc """
  Deletes a notification.
  """
  def delete_notification(%Notification{} = notification) do
    Repo.delete(notification)
  end
end

defmodule Pingbase.Chat.RoomMembership do
  @moduledoc """
  The RoomMembership schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_membership" do
    field :last_read_message_id, :integer
    field :notification_level, :string, default: "all"

    belongs_to :room, Pingbase.Chat.Room
    belongs_to :user, Pingbase.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:last_read_message_id, :notification_level, :room_id, :user_id])
    |> validate_required([:notification_level, :room_id, :user_id])
    |> validate_inclusion(:notification_level, ["all", "mentions", "none"])
    |> unique_constraint([:room_id, :user_id])
  end
end

defmodule Pingbase.Chat.Room do
  @moduledoc """
  The Room schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "room" do
    field :type, :string, default: "channel"
    field :name, :string
    field :slug, :string
    field :topic, :string
    field :is_archived, :boolean, default: false

    belongs_to :workspace, Pingbase.Workspaces.Workspace
    has_many :memberships, Pingbase.Chat.RoomMembership
    has_many :messages, Pingbase.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:type, :name, :slug, :topic, :is_archived, :workspace_id])
    |> validate_required([:type, :name, :slug, :workspace_id])
    |> validate_inclusion(:type, ["channel", "dm", "thread"])
    |> unique_constraint([:workspace_id, :slug])
  end
end

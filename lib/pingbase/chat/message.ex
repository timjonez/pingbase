defmodule Pingbase.Chat.Message do
  @moduledoc """
  The Message schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "message" do
    field :content, :string
    field :edited_at, :utc_datetime

    belongs_to :room, Pingbase.Chat.Room
    belongs_to :user, Pingbase.Accounts.User
    belongs_to :parent, Pingbase.Chat.Message
    has_many :reactions, Pingbase.Chat.MessageReaction
    has_many :mentions, Pingbase.Chat.MessageMention
    has_many :attachments, Pingbase.Chat.Attachment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :edited_at, :room_id, :user_id, :parent_id])
    |> validate_required([:content, :room_id, :user_id])
    |> validate_length(:content, min: 1, max: 10000)
    |> foreign_key_constraint(:room_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:parent_id)
  end
end

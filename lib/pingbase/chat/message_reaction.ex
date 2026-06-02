defmodule Pingbase.Chat.MessageReaction do
  @moduledoc """
  The MessageReaction schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "message_reaction" do
    field :emoji, :string

    belongs_to :message, Pingbase.Chat.Message
    belongs_to :user, Pingbase.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:emoji, :message_id, :user_id])
    |> validate_required([:emoji, :message_id, :user_id])
    |> unique_constraint([:message_id, :user_id, :emoji])
  end
end

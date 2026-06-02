defmodule Pingbase.Chat.MessageMention do
  @moduledoc """
  The MessageMention schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "message_mention" do
    belongs_to :message, Pingbase.Chat.Message
    belongs_to :mentioned_user, Pingbase.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mention, attrs) do
    mention
    |> cast(attrs, [:message_id, :mentioned_user_id])
    |> validate_required([:message_id, :mentioned_user_id])
    |> unique_constraint([:message_id, :mentioned_user_id])
  end
end

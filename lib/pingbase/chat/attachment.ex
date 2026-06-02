defmodule Pingbase.Chat.Attachment do
  @moduledoc """
  The Attachment schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "attachment" do
    field :filename, :string
    field :url, :string
    field :size, :integer
    field :mime_type, :string

    belongs_to :message, Pingbase.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:filename, :url, :size, :mime_type, :message_id])
    |> validate_required([:filename, :url, :message_id])
  end
end

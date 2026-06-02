defmodule Pingbase.Notifications.Notification do
  @moduledoc """
  The Notification schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "notification" do
    field :type, :string
    field :resource_type, :string
    field :resource_id, :integer
    field :read_at, :utc_datetime

    belongs_to :user, Pingbase.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:type, :resource_type, :resource_id, :read_at, :user_id])
    |> validate_required([:type, :user_id])
    |> validate_inclusion(:type, ["mention", "invite", "thread_reply", "billing_alert"])
  end
end

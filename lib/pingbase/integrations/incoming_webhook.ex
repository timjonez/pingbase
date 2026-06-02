defmodule Pingbase.Integrations.IncomingWebhook do
  @moduledoc """
  The IncomingWebhook schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "incoming_webhook" do
    field :name, :string
    field :token, :string

    belongs_to :workspace, Pingbase.Workspaces.Workspace
    belongs_to :room, Pingbase.Chat.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:name, :token, :workspace_id, :room_id])
    |> validate_required([:name, :token, :workspace_id, :room_id])
    |> unique_constraint(:token)
  end
end

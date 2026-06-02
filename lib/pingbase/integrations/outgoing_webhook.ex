defmodule Pingbase.Integrations.OutgoingWebhook do
  @moduledoc """
  The OutgoingWebhook schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "outgoing_webhook" do
    field :name, :string
    field :url, :string
    field :events, {:array, :string}, default: []
    field :active, :boolean, default: true

    belongs_to :workspace, Pingbase.Workspaces.Workspace

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:name, :url, :events, :active, :workspace_id])
    |> validate_required([:name, :url, :workspace_id])
    |> validate_format(:url, ~r/^https?:\/\/.+/)
  end
end

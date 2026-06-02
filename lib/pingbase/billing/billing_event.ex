defmodule Pingbase.Billing.BillingEvent do
  @moduledoc """
  The BillingEvent schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "billing_event" do
    field :event_type, :string
    field :amount, :integer
    field :metadata, :map, default: %{}

    belongs_to :workspace, Pingbase.Workspaces.Workspace

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:event_type, :amount, :metadata, :workspace_id])
    |> validate_required([:event_type, :workspace_id])
  end
end

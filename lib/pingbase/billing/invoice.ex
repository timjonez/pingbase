defmodule Pingbase.Billing.Invoice do
  @moduledoc """
  The Invoice schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "invoice" do
    field :stripe_invoice_id, :string
    field :amount_due, :integer
    field :amount_paid, :integer
    field :status, :string
    field :period_start, :utc_datetime
    field :period_end, :utc_datetime

    belongs_to :workspace, Pingbase.Workspaces.Workspace

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [:stripe_invoice_id, :amount_due, :amount_paid, :status, :period_start, :period_end, :workspace_id])
    |> validate_required([:workspace_id])
    |> unique_constraint(:stripe_invoice_id)
  end
end

defmodule Pingbase.Billing do
  @moduledoc """
  The Billing context.

  This context is responsible for managing Stripe customers,
  subscriptions, invoices, and plan enforcement.
  """

  import Ecto.Query, warn: false
  alias Pingbase.Repo

  alias Pingbase.Workspaces.Workspace
  alias Pingbase.Billing.BillingEvent
  alias Pingbase.Billing.Invoice

  @free_seats 10

  @doc """
  Returns whether a workspace can add more members.
  """
  def can_add_member?(%Workspace{} = workspace) do
    # Self-hosted workspaces have no limits
    if is_nil(workspace.stripe_customer_id) do
      true
    else
      workspace.seats_count < workspace.seats_limit
    end
  end

  @doc """
  Increments the seat count for a workspace.
  """
  def increment_seats(%Workspace{} = workspace) do
    workspace
    |> Ecto.Changeset.change(seats_count: workspace.seats_count + 1)
    |> Repo.update()
  end

  @doc """
  Decrements the seat count for a workspace.
  """
  def decrement_seats(%Workspace{} = workspace) do
    new_count = max(workspace.seats_count - 1, 0)

    workspace
    |> Ecto.Changeset.change(seats_count: new_count)
    |> Repo.update()
  end

  @doc """
  Creates a Stripe customer for a workspace.
  """
  def create_stripe_customer(%Workspace{} = workspace, email) do
    # This is a stub for the Stripe integration
    # In production, this would call Stripe API
    stripe_customer_id = "cus_" <> Ecto.UUID.generate() |> String.replace("-", "")

    workspace
    |> Ecto.Changeset.change(
      stripe_customer_id: stripe_customer_id,
      plan: "team"
    )
    |> Repo.update()
  end

  @doc """
  Creates a billing event.
  """
  def create_billing_event(attrs \\ %{}) do
    %BillingEvent{}
    |> BillingEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists billing events for a workspace.
  """
  def list_workspace_billing_events(%Workspace{} = workspace) do
    BillingEvent
    |> where(workspace_id: ^workspace.id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Creates an invoice record.
  """
  def create_invoice(attrs \\ %{}) do
    %Invoice{}
    |> Invoice.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists invoices for a workspace.
  """
  def list_workspace_invoices(%Workspace{} = workspace) do
    Invoice
    |> where(workspace_id: ^workspace.id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Calculates the seat limit for a workspace based on its plan.
  """
  def seat_limit_for_plan("free"), do: @free_seats
  def seat_limit_for_plan("team"), do: nil
  def seat_limit_for_plan("enterprise"), do: nil
  def seat_limit_for_plan(_), do: @free_seats

  @doc """
  Returns the free tier seat limit.
  """
  def free_seats, do: @free_seats
end

defmodule Pingbase.Workspaces.Workspace do
  @moduledoc """
  The Workspace schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "workspace" do
    field :slug, :string
    field :name, :string
    field :description, :string
    field :avatar_url, :string
    field :plan, :string, default: "free"
    field :billing_status, :string, default: "active"
    field :stripe_customer_id, :string
    field :stripe_subscription_id, :string
    field :seats_count, :integer, default: 0
    field :seats_limit, :integer, default: 10
    field :trial_ends_at, :utc_datetime

    has_many :memberships, Pingbase.Workspaces.WorkspaceMembership
    has_many :invites, Pingbase.Workspaces.WorkspaceInvite
    has_many :rooms, Pingbase.Chat.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [:slug, :name, :description, :avatar_url, :plan, :billing_status, :stripe_customer_id, :stripe_subscription_id, :seats_count, :seats_limit, :trial_ends_at])
    |> validate_required([:slug, :name])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/)
    |> validate_length(:slug, min: 2, max: 50)
    |> unique_constraint(:slug)
  end
end

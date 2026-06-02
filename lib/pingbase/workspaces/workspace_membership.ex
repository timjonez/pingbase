defmodule Pingbase.Workspaces.WorkspaceMembership do
  @moduledoc """
  The WorkspaceMembership schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "workspace_membership" do
    field :role, :string, default: "member"
    field :notification_pref, :string, default: "all"

    belongs_to :user, Pingbase.Accounts.User
    belongs_to :workspace, Pingbase.Workspaces.Workspace

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role, :notification_pref, :user_id, :workspace_id])
    |> validate_required([:role, :user_id, :workspace_id])
    |> validate_inclusion(:role, ["owner", "admin", "member"])
    |> validate_inclusion(:notification_pref, ["all", "mentions", "none"])
    |> unique_constraint([:user_id, :workspace_id])
  end
end

defmodule Pingbase.Workspaces.WorkspaceInvite do
  @moduledoc """
  The WorkspaceInvite schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "workspace_invite" do
    field :email, :string
    field :accepted_at, :utc_datetime
    field :expires_at, :utc_datetime

    belongs_to :workspace, Pingbase.Workspaces.Workspace
    belongs_to :invited_by_user, Pingbase.Accounts.User, foreign_key: :invited_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email, :accepted_at, :expires_at, :workspace_id, :invited_by_user_id])
    |> validate_required([:email, :expires_at, :workspace_id, :invited_by_user_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
  end
end

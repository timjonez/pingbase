defmodule Pingbase.Repo.Migrations.CreateWorkspaceInvites do
  use Ecto.Migration

  def change do
    create table(:workspace_invite) do
      add :workspace_id, references(:workspace, on_delete: :delete_all), null: false
      add :email, :string, null: false
      add :invited_by_user_id, references(:user, on_delete: :delete_all), null: false
      add :accepted_at, :utc_datetime
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:workspace_invite, [:workspace_id])
    create index(:workspace_invite, [:email])
  end
end

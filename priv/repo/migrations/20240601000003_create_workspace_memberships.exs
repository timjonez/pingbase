defmodule Pingbase.Repo.Migrations.CreateWorkspaceMemberships do
  use Ecto.Migration

  def change do
    create table(:workspace_membership) do
      add :user_id, references(:user, on_delete: :delete_all), null: false
      add :workspace_id, references(:workspace, on_delete: :delete_all), null: false
      add :role, :string, default: "member", null: false
      add :notification_pref, :string, default: "all"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:workspace_membership, [:user_id, :workspace_id])
    create index(:workspace_membership, [:workspace_id])
  end
end

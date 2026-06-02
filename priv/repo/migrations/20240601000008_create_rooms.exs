defmodule Pingbase.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:room) do
      add :workspace_id, references(:workspace, on_delete: :delete_all), null: false
      add :type, :string, default: "channel", null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :topic, :string
      add :is_archived, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:room, [:workspace_id])
    create unique_index(:room, [:workspace_id, :slug])
  end
end

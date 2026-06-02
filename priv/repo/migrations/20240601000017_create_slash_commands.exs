defmodule Pingbase.Repo.Migrations.CreateSlashCommands do
  use Ecto.Migration

  def change do
    create table(:slash_command) do
      add :workspace_id, references(:workspace, on_delete: :delete_all), null: false
      add :command, :string, null: false
      add :description, :string
      add :url, :string, null: false
      add :token, :string, null: false
      add :room_id, references(:room, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:slash_command, [:workspace_id, :command])
    create index(:slash_command, [:workspace_id])
  end
end

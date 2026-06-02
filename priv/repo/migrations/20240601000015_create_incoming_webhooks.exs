defmodule Pingbase.Repo.Migrations.CreateIncomingWebhooks do
  use Ecto.Migration

  def change do
    create table(:incoming_webhook) do
      add :workspace_id, references(:workspace, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :token, :string, null: false
      add :room_id, references(:room, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:incoming_webhook, [:token])
    create index(:incoming_webhook, [:workspace_id])
  end
end

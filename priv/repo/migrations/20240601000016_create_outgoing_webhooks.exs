defmodule Pingbase.Repo.Migrations.CreateOutgoingWebhooks do
  use Ecto.Migration

  def change do
    create table(:outgoing_webhook) do
      add :workspace_id, references(:workspace, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :url, :string, null: false
      add :events, {:array, :string}, default: []
      add :active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:outgoing_webhook, [:workspace_id])
  end
end

defmodule Pingbase.Repo.Migrations.CreateBillingEvents do
  use Ecto.Migration

  def change do
    create table(:billing_event) do
      add :workspace_id, references(:workspace, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :amount, :integer
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:billing_event, [:workspace_id])
    create index(:billing_event, [:event_type])
  end
end

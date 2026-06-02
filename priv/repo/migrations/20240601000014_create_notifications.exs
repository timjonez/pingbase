defmodule Pingbase.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notification) do
      add :user_id, references(:user, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :resource_type, :string
      add :resource_id, :integer
      add :read_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:notification, [:user_id])
    create index(:notification, [:read_at])
  end
end

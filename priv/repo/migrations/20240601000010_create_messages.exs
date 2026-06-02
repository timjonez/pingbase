defmodule Pingbase.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:message) do
      add :room_id, references(:room, on_delete: :delete_all), null: false
      add :user_id, references(:user, on_delete: :delete_all), null: false
      add :parent_id, references(:message, on_delete: :nilify_all)
      add :content, :text, null: false
      add :edited_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:message, [:room_id])
    create index(:message, [:user_id])
    create index(:message, [:parent_id])
  end
end

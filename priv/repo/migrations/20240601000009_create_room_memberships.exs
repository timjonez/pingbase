defmodule Pingbase.Repo.Migrations.CreateRoomMemberships do
  use Ecto.Migration

  def change do
    create table(:room_membership) do
      add :room_id, references(:room, on_delete: :delete_all), null: false
      add :user_id, references(:user, on_delete: :delete_all), null: false
      add :last_read_message_id, :integer
      add :notification_level, :string, default: "all"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:room_membership, [:room_id, :user_id])
    create index(:room_membership, [:user_id])
  end
end

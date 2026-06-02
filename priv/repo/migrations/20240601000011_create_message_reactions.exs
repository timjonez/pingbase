defmodule Pingbase.Repo.Migrations.CreateMessageReactions do
  use Ecto.Migration

  def change do
    create table(:message_reaction) do
      add :message_id, references(:message, on_delete: :delete_all), null: false
      add :user_id, references(:user, on_delete: :delete_all), null: false
      add :emoji, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:message_reaction, [:message_id, :user_id, :emoji])
    create index(:message_reaction, [:message_id])
  end
end

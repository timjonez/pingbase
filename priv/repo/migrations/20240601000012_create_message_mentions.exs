defmodule Pingbase.Repo.Migrations.CreateMessageMentions do
  use Ecto.Migration

  def change do
    create table(:message_mention) do
      add :message_id, references(:message, on_delete: :delete_all), null: false
      add :mentioned_user_id, references(:user, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:message_mention, [:message_id, :mentioned_user_id])
    create index(:message_mention, [:mentioned_user_id])
  end
end

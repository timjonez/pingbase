defmodule Pingbase.Repo.Migrations.CreateAttachments do
  use Ecto.Migration

  def change do
    create table(:attachment) do
      add :message_id, references(:message, on_delete: :delete_all), null: false
      add :filename, :string, null: false
      add :url, :string, null: false
      add :size, :integer
      add :mime_type, :string

      timestamps(type: :utc_datetime)
    end

    create index(:attachment, [:message_id])
  end
end

defmodule Pingbase.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:user) do
      add :email, :string, null: false
      add :name, :string
      add :display_name, :string
      add :avatar_url, :string
      add :timezone, :string, default: "UTC"
      add :status_text, :string
      add :status_emoji, :string
      add :confirmed_at, :utc_datetime
      add :magic_link_hash, :string
      add :magic_link_expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user, [:email])
  end
end

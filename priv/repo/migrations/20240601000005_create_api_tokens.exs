defmodule Pingbase.Repo.Migrations.CreateApiTokens do
  use Ecto.Migration

  def change do
    create table(:api_token) do
      add :user_id, references(:user, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :token_hash, :string, null: false
      add :last_used_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:api_token, [:token_hash])
    create index(:api_token, [:user_id])
  end
end

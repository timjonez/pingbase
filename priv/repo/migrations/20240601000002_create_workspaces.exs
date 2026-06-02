defmodule Pingbase.Repo.Migrations.CreateWorkspaces do
  use Ecto.Migration

  def change do
    create table(:workspace) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :description, :text
      add :avatar_url, :string
      add :plan, :string, default: "free"
      add :billing_status, :string, default: "active"
      add :stripe_customer_id, :string
      add :stripe_subscription_id, :string
      add :seats_count, :integer, default: 0
      add :seats_limit, :integer, default: 10
      add :trial_ends_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:workspace, [:slug])
    create index(:workspace, [:stripe_customer_id])
  end
end

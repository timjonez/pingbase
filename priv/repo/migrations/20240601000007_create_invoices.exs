defmodule Pingbase.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoice) do
      add :workspace_id, references(:workspace, on_delete: :delete_all), null: false
      add :stripe_invoice_id, :string
      add :amount_due, :integer
      add :amount_paid, :integer
      add :status, :string
      add :period_start, :utc_datetime
      add :period_end, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:invoice, [:workspace_id])
    create unique_index(:invoice, [:stripe_invoice_id])
  end
end

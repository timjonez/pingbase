defmodule Pingbase.Repo.Migrations.AddTokenToWorkspaceInvites do
  use Ecto.Migration

  def change do
    alter table(:workspace_invite) do
      add :token_hash, :string
    end

    create unique_index(:workspace_invite, [:token_hash])
  end
end

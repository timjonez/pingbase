defmodule Pingbase.Integrations.SlashCommand do
  @moduledoc """
  The SlashCommand schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "slash_command" do
    field :command, :string
    field :description, :string
    field :url, :string
    field :token, :string

    belongs_to :workspace, Pingbase.Workspaces.Workspace
    belongs_to :room, Pingbase.Chat.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(slash_command, attrs) do
    slash_command
    |> cast(attrs, [:command, :description, :url, :token, :workspace_id, :room_id])
    |> validate_required([:command, :url, :token, :workspace_id])
    |> validate_format(:command, ~r/^\/[a-z0-9-]+$/)
    |> unique_constraint([:workspace_id, :command])
  end
end

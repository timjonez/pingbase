defmodule Pingbase.Accounts.User do
  @moduledoc """
  The User schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "user" do
    field :email, :string
    field :name, :string
    field :display_name, :string
    field :avatar_url, :string
    field :timezone, :string, default: "UTC"
    field :status_text, :string
    field :status_emoji, :string
    field :confirmed_at, :utc_datetime
    field :magic_link_hash, :string
    field :magic_link_expires_at, :utc_datetime

    has_many :workspace_memberships, Pingbase.Workspaces.WorkspaceMembership
    has_many :api_tokens, Pingbase.Accounts.ApiToken

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :display_name, :avatar_url, :timezone, :status_text, :status_emoji, :confirmed_at, :magic_link_hash, :magic_link_expires_at])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email)
  end
end

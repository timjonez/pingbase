defmodule Pingbase.Accounts.ApiToken do
  @moduledoc """
  The API Token schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "api_token" do
    field :name, :string
    field :token_hash, :string
    field :last_used_at, :utc_datetime

    belongs_to :user, Pingbase.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_token, attrs) do
    api_token
    |> cast(attrs, [:name, :token_hash, :last_used_at, :user_id])
    |> validate_required([:name, :token_hash, :user_id])
    |> unique_constraint(:token_hash)
  end
end

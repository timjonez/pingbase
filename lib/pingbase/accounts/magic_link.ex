defmodule Pingbase.Accounts.MagicLink do
  @moduledoc """
  Handles magic link generation and verification for passwordless authentication.
  """
  
  alias Pingbase.Accounts.User
  alias Pingbase.Repo
  
  @magic_link_expiration_hours 24
  
  @doc """
  Generates a magic link token for a user.
  Returns {token, hashed_token} for storage and email.
  """
  def generate_token do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    hashed = :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
    {token, hashed}
  end
  
  @doc """
  Stores a magic link token for a user with expiration.
  """
  def store_token(%User{} = user, hashed_token) do
    expires_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(@magic_link_expiration_hours, :hour)

    user
    |> Ecto.Changeset.change(%{
      magic_link_hash: hashed_token,
      magic_link_expires_at: expires_at
    })
    |> Repo.update()
  end
  
  @doc """
  Verifies a magic link token and returns the user if valid.
  """
  def verify_token(token) when is_binary(token) do
    hashed = :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
    
    case Repo.get_by(User, magic_link_hash: hashed) do
      nil ->
        :error
        
      %User{magic_link_expires_at: nil} ->
        :error
        
      %User{magic_link_expires_at: expires_at} = user ->
        if DateTime.compare(expires_at, DateTime.utc_now() |> DateTime.truncate(:second)) == :gt do
          # Clear the magic link after use
          user
          |> Ecto.Changeset.change(%{
            magic_link_hash: nil,
            magic_link_expires_at: nil,
            confirmed_at: user.confirmed_at || DateTime.utc_now() |> DateTime.truncate(:second)
          })
          |> Repo.update!()

          {:ok, user}
        else
          :error
        end
    end
  end
end

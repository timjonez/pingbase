defmodule Pingbase.Accounts do
  @moduledoc """
  The Accounts context.

  This context is responsible for managing users, authentication,
  sessions, and API tokens.
  """

  import Ecto.Query, warn: false
  alias Pingbase.Repo

  alias Pingbase.Accounts.User
  alias Pingbase.Accounts.ApiToken

  ## Users

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  ## API Tokens

  @doc """
  Creates an API token for a user.
  """
  def create_api_token(user, name) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    token_hash = :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)

    %ApiToken{}
    |> ApiToken.changeset(%{
      name: name,
      token_hash: token_hash,
      user_id: user.id
    })
    |> Repo.insert()
    |> case do
      {:ok, api_token} -> {:ok, api_token, token}
      error -> error
    end
  end

  @doc """
  Validates an API token and returns the associated user.
  """
  def validate_api_token(token) when is_binary(token) do
    token_hash = :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)

    case Repo.get_by(ApiToken, token_hash: token_hash) do
      nil ->
        :error

      api_token ->
        api_token
        |> Ecto.Changeset.change(last_used_at: DateTime.utc_now() |> DateTime.truncate(:second))
        |> Repo.update!()

        {:ok, Repo.preload(api_token, :user).user}
    end
  end

  @doc """
  Deletes an API token.
  """
  def delete_api_token(%ApiToken{} = api_token) do
    Repo.delete(api_token)
  end

  @doc """
  Lists API tokens for a user.
  """
  def list_user_api_tokens(user) do
    ApiToken
    |> where(user_id: ^user.id)
    |> Repo.all()
  end
end

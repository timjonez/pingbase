defmodule Pingbase.Workspaces do
  @moduledoc """
  The Workspaces context.

  This context is responsible for managing workspaces,
  memberships, and invites.
  """

  import Ecto.Query, warn: false
  alias Pingbase.Repo

  alias Pingbase.Workspaces.Workspace
  alias Pingbase.Workspaces.WorkspaceMembership
  alias Pingbase.Workspaces.WorkspaceInvite
  alias Pingbase.Accounts.User
  alias Pingbase.Accounts.UserNotifier

  ## Workspaces

  @doc """
  Returns the list of workspaces.
  """
  def list_workspaces do
    Repo.all(Workspace)
  end

  @doc """
  Gets a single workspace.

  Raises `Ecto.NoResultsError` if the Workspace does not exist.
  """
  def get_workspace!(id), do: Repo.get!(Workspace, id)

  @doc """
  Gets a workspace by slug.
  """
  def get_workspace_by_slug(slug) do
    Repo.get_by(Workspace, slug: slug)
  end

  @doc """
  Creates a workspace and assigns the creator as owner.
  """
  def create_workspace(%User{} = user, attrs \\ %{}) do
    Repo.transaction(fn ->
      workspace =
        %Workspace{}
        |> Workspace.changeset(attrs)
        |> Repo.insert!()

      %WorkspaceMembership{}
      |> WorkspaceMembership.changeset(%{
        user_id: user.id,
        workspace_id: workspace.id,
        role: "owner"
      })
      |> Repo.insert!()

      workspace
    end)
  end

  @doc """
  Updates a workspace.
  """
  def update_workspace(%Workspace{} = workspace, attrs) do
    workspace
    |> Workspace.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a workspace.
  """
  def delete_workspace(%Workspace{} = workspace) do
    Repo.delete(workspace)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workspace changes.
  """
  def change_workspace(%Workspace{} = workspace, attrs \\ %{}) do
    Workspace.changeset(workspace, attrs)
  end

  ## Memberships

  @doc """
  Lists memberships for a workspace.
  """
  def list_workspace_memberships(%Workspace{} = workspace) do
    WorkspaceMembership
    |> where(workspace_id: ^workspace.id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Lists workspaces for a user.
  """
  def list_user_workspaces(%User{} = user) do
    WorkspaceMembership
    |> where(user_id: ^user.id)
    |> preload(:workspace)
    |> Repo.all()
    |> Enum.map(& &1.workspace)
  end

  @doc """
  Gets a membership for a user in a workspace.
  """
  def get_membership(%User{} = user, %Workspace{} = workspace) do
    WorkspaceMembership
    |> where(user_id: ^user.id, workspace_id: ^workspace.id)
    |> Repo.one()
  end

  @doc """
  Gets a membership for a user in a workspace, raising if not found.
  """
  def get_membership!(%User{} = user, %Workspace{} = workspace) do
    WorkspaceMembership
    |> where(user_id: ^user.id, workspace_id: ^workspace.id)
    |> Repo.one!()
  end

  @doc """
  Updates a workspace membership.
  """
  def update_membership(%WorkspaceMembership{} = membership, attrs) do
    membership
    |> WorkspaceMembership.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Adds a member to a workspace.
  """
  def add_member(%Workspace{} = workspace, %User{} = user, role \\ "member") do
    %WorkspaceMembership{}
    |> WorkspaceMembership.changeset(%{
      user_id: user.id,
      workspace_id: workspace.id,
      role: role
    })
    |> Repo.insert()
  end

  @doc """
  Removes a member from a workspace.
  """
  def remove_member(%Workspace{} = workspace, %User{} = user) do
    WorkspaceMembership
    |> where(user_id: ^user.id, workspace_id: ^workspace.id)
    |> Repo.one!()
    |> Repo.delete()
  end

  ## Invites

  @doc """
  Creates an invite for a workspace.
  """
  def create_invite(%Workspace{} = workspace, %User{} = invited_by, email) do
    expires_at = DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)

    {token, token_hash} = generate_invite_token()

    result =
      %WorkspaceInvite{}
      |> WorkspaceInvite.changeset(%{
        email: email,
        token_hash: token_hash,
        workspace_id: workspace.id,
        invited_by_user_id: invited_by.id,
        expires_at: expires_at
      })
      |> Repo.insert()

    with {:ok, _invite} <- result do
      link = PingbaseWeb.Endpoint.url() <> "/join/#{token}"
      UserNotifier.deliver_workspace_invite(email, workspace, invited_by, link)
    end

    result
  end

  @doc """
  Gets a pending invite by its raw token.
  """
  def get_invite_by_token(token) when is_binary(token) do
    token_hash = :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)

    WorkspaceInvite
    |> where(token_hash: ^token_hash)
    |> where([i], is_nil(i.accepted_at))
    |> where([i], i.expires_at > ^DateTime.utc_now())
    |> preload(:workspace)
    |> Repo.one()
  end

  @doc """
  Accepts an invite by its raw token for a given user.
  """
  def accept_invite_by_token(token, %User{} = user) when is_binary(token) do
    case get_invite_by_token(token) do
      nil ->
        {:error, :invalid_or_expired_invite}

      invite ->
        accept_invite(invite, user)
    end
  end

  @doc """
  Accepts an invite.
  """
  def accept_invite(%WorkspaceInvite{} = invite, %User{} = user) do
    Repo.transaction(fn ->
      invite
      |> Ecto.Changeset.change(accepted_at: DateTime.utc_now() |> DateTime.truncate(:second))
      |> Repo.update!()

      workspace = get_workspace!(invite.workspace_id)

      case get_membership(user, workspace) do
        nil -> add_member(workspace, user)
        _membership -> {:ok, :already_member}
      end
    end)
  end

  @doc """
  Lists pending invites for a workspace.
  """
  def list_workspace_invites(%Workspace{} = workspace) do
    WorkspaceInvite
    |> where(workspace_id: ^workspace.id)
    |> where([i], is_nil(i.accepted_at))
    |> where([i], i.expires_at > ^DateTime.utc_now())
    |> preload(:invited_by_user)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Cancels an invite.
  """
  def cancel_invite(%WorkspaceInvite{} = invite) do
    Repo.delete(invite)
  end

  defp generate_invite_token do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    hashed = :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
    {token, hashed}
  end
end

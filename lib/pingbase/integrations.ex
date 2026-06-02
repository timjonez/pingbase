defmodule Pingbase.Integrations do
  @moduledoc """
  The Integrations context.

  This context is responsible for managing incoming/outgoing
  webhooks and slash commands.
  """

  import Ecto.Query, warn: false
  alias Pingbase.Repo

  alias Pingbase.Integrations.IncomingWebhook
  alias Pingbase.Integrations.OutgoingWebhook
  alias Pingbase.Integrations.SlashCommand

  alias Pingbase.Workspaces.Workspace

  ## Incoming Webhooks

  @doc """
  Creates an incoming webhook.
  """
  def create_incoming_webhook(attrs \\ %{}) do
    %IncomingWebhook{}
    |> IncomingWebhook.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an incoming webhook by token.
  """
  def get_incoming_webhook_by_token(token) do
    IncomingWebhook
    |> where(token: ^token)
    |> preload([:workspace, :room])
    |> Repo.one()
  end

  ## Outgoing Webhooks

  @doc """
  Creates an outgoing webhook.
  """
  def create_outgoing_webhook(attrs \\ %{}) do
    %OutgoingWebhook{}
    |> OutgoingWebhook.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists active outgoing webhooks for a workspace.
  """
  def list_active_outgoing_webhooks(%Workspace{} = workspace) do
    OutgoingWebhook
    |> where(workspace_id: ^workspace.id, active: true)
    |> Repo.all()
  end

  ## Slash Commands

  @doc """
  Creates a slash command.
  """
  def create_slash_command(attrs \\ %{}) do
    %SlashCommand{}
    |> SlashCommand.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a slash command by workspace and command name.
  """
  def get_slash_command(%Workspace{} = workspace, command) do
    SlashCommand
    |> where(workspace_id: ^workspace.id, command: ^command)
    |> Repo.one()
  end
end

defmodule Pingbase.WorkspacesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pingbase.Workspaces` context.
  """

  alias Pingbase.AccountsFixtures
  alias Pingbase.Workspaces

  def workspace_fixture(attrs \\ %{}) do
    user = attrs[:user] || AccountsFixtures.user_fixture()

    {:ok, workspace} =
      Workspaces.create_workspace(
        user,
        Enum.into(attrs, %{
          slug: "workspace-#{System.unique_integer()}",
          name: "Test Workspace"
        })
      )

    workspace
  end
end

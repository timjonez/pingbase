defmodule Pingbase.WorkspacesTest do
  use Pingbase.DataCase

  alias Pingbase.Workspaces

  describe "workspaces" do
    alias Pingbase.Workspaces.Workspace

    import Pingbase.AccountsFixtures
    import Pingbase.WorkspacesFixtures

    @invalid_attrs %{slug: nil, name: nil}

    test "list_workspaces/0 returns all workspaces" do
      workspace = workspace_fixture()
      assert length(Workspaces.list_workspaces()) >= 1
    end

    test "get_workspace!/1 returns the workspace with given id" do
      workspace = workspace_fixture()
      assert Workspaces.get_workspace!(workspace.id).id == workspace.id
    end

    test "create_workspace/2 with valid data creates a workspace and membership" do
      user = user_fixture()
      valid_attrs = %{slug: "test-workspace", name: "Test Workspace"}

      assert {:ok, %Workspace{} = workspace} = Workspaces.create_workspace(user, valid_attrs)
      assert workspace.slug == "test-workspace"
      assert workspace.name == "Test Workspace"
    end

    test "update_workspace/2 with valid data updates the workspace" do
      workspace = workspace_fixture()
      update_attrs = %{name: "Updated Workspace"}

      assert {:ok, %Workspace{} = workspace} = Workspaces.update_workspace(workspace, update_attrs)
      assert workspace.name == "Updated Workspace"
    end

    test "delete_workspace/1 deletes the workspace" do
      workspace = workspace_fixture()
      assert {:ok, %Workspace{}} = Workspaces.delete_workspace(workspace)
      assert_raise Ecto.NoResultsError, fn -> Workspaces.get_workspace!(workspace.id) end
    end
  end
end

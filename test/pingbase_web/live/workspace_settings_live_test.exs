defmodule PingbaseWeb.WorkspaceSettingsLiveTest do
  use PingbaseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pingbase.AccountsFixtures
  import Pingbase.WorkspacesFixtures

  alias Pingbase.Workspaces

  describe "WorkspaceSettingsLive.General" do
    test "requires authentication", %{conn: conn} do
      workspace = workspace_fixture()

      {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/w/#{workspace.slug}/settings/general")
    end

    test "requires workspace membership", %{conn: conn} do
      user = user_fixture()
      workspace = workspace_fixture()
      conn = log_in_user(conn, user)

      {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/w/#{workspace.slug}/settings/general")
    end

    test "owner can update workspace", %{conn: conn} do
      user = user_fixture()
      workspace = workspace_fixture(user: user)
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/settings/general")

      lv
      |> form("form", workspace: %{name: "Updated Workspace"})
      |> render_submit()

      html = render(lv)
      assert html =~ "Updated Workspace"
      assert html =~ "Workspace updated successfully"
    end

    test "member cannot update workspace", %{conn: conn} do
      owner = user_fixture()
      member = user_fixture()
      workspace = workspace_fixture(user: owner)
      Workspaces.add_member(workspace, member)

      conn = log_in_user(conn, member)
      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/settings/general")

      assert render(lv) =~ "disabled"
    end
  end

  describe "WorkspaceSettingsLive.Members" do
    test "owner can invite and manage members", %{conn: conn} do
      owner = user_fixture()
      workspace = workspace_fixture(user: owner)
      conn = log_in_user(conn, owner)

      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/settings/members")

      assert render(lv) =~ "Invite Members"

      lv
      |> form("form", invite: %{email: "new@example.com"})
      |> render_submit()

      html = render(lv)
      assert html =~ "new@example.com"
      assert html =~ "Invite sent"
    end

    test "member cannot see invite form", %{conn: conn} do
      owner = user_fixture()
      member = user_fixture()
      workspace = workspace_fixture(user: owner)
      Workspaces.add_member(workspace, member)

      conn = log_in_user(conn, member)
      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/settings/members")

      html = render(lv)
      refute html =~ "Invite Members"
      assert html =~ "Workspace Members"
    end
  end

  describe "WorkspaceSettingsLive.Notifications" do
    test "updates workspace notification preference", %{conn: conn} do
      user = user_fixture()
      workspace = workspace_fixture(user: user)
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/settings/notifications")

      lv
      |> form("form", notification_pref: "mentions")
      |> render_submit()

      html = render(lv)
      assert html =~ "Notification preference updated"
    end
  end

  describe "WorkspaceSettingsLive.Billing" do
    test "requires admin access", %{conn: conn} do
      owner = user_fixture()
      member = user_fixture()
      workspace = workspace_fixture(user: owner)
      Workspaces.add_member(workspace, member)

      conn = log_in_user(conn, member)
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/w/#{workspace.slug}/settings/billing")
      assert path == ~p"/w/#{workspace.slug}"
    end

    test "owner can view billing", %{conn: conn} do
      user = user_fixture()
      workspace = workspace_fixture(user: user)
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/w/#{workspace.slug}/settings/billing")
      assert html =~ "Billing"
      assert html =~ workspace.plan
    end
  end

  describe "WorkspaceSettingsLive.Integrations" do
    test "requires admin access", %{conn: conn} do
      owner = user_fixture()
      member = user_fixture()
      workspace = workspace_fixture(user: owner)
      Workspaces.add_member(workspace, member)

      conn = log_in_user(conn, member)
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/w/#{workspace.slug}/settings/integrations")
      assert path == ~p"/w/#{workspace.slug}"
    end

    test "owner can view integrations", %{conn: conn} do
      user = user_fixture()
      workspace = workspace_fixture(user: user)
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/w/#{workspace.slug}/settings/integrations")
      assert html =~ "Integrations"
      assert html =~ "Incoming Webhooks"
    end
  end
end

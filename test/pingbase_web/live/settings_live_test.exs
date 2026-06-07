defmodule PingbaseWeb.SettingsLiveTest do
  use PingbaseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pingbase.AccountsFixtures

  describe "SettingsLive.Profile" do
    test "requires authentication", %{conn: conn} do
      {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/settings/profile")
    end

    test "renders profile settings for authenticated user", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/settings/profile")
      assert html =~ "Profile"
      assert html =~ user.name
    end

    test "updates profile", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/settings/profile")

      lv
      |> form("form", user: %{name: "Updated Name", display_name: "Upd8"})
      |> render_submit()

      html = render(lv)
      assert html =~ "Updated Name"
      assert html =~ "Profile updated successfully"
    end
  end

  describe "SettingsLive.Tokens" do
    test "requires authentication", %{conn: conn} do
      {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/settings/tokens")
    end

    test "renders tokens page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/settings/tokens")
      assert html =~ "API Tokens"
    end

    test "creates and revokes a token", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/settings/tokens")

      lv
      |> form("form", token: %{name: "Test Token"})
      |> render_submit()

      html = render(lv)
      assert html =~ "Test Token"
      assert html =~ "API token created"

      lv
      |> element("button", "Revoke")
      |> render_click()

      html = render(lv)
      assert html =~ "don&#39;t have any API tokens yet"
    end
  end
end

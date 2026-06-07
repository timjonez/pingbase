defmodule PingbaseWeb.SignInLiveTest do
  use PingbaseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pingbase.AccountsFixtures

  alias Pingbase.Accounts
  alias Pingbase.Accounts.MagicLink

  describe "Sign-in page" do
    test "renders sign-in form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, "/sign-in")
      assert html =~ "Sign in to Pingbase"
      assert html =~ "Send Magic Link"
    end

    test "redirects already signed-in users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/sign-in")
    end

    test "sending magic link for existing user", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = live(conn, "/sign-in")

      html =
        lv
        |> form("form", user: %{email: user.email})
        |> render_submit()

      assert html =~ "Check your email"

      # Verify token was stored
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.magic_link_hash != nil
    end

    test "sending magic link for non-existing user shows same message", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/sign-in")

      html =
        lv
        |> form("form", user: %{email: "nobody@example.com"})
        |> render_submit()

      assert html =~ "Check your email"
    end
  end
end

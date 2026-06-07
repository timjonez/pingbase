defmodule PingbaseWeb.OnboardingLiveTest do
  use PingbaseWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Onboarding" do
    test "renders welcome step", %{conn: conn} do
      {:ok, _lv, html} = live(conn, "/onboarding")
      assert html =~ "Welcome to Pingbase"
      assert html =~ "Get Started"
    end

    test "renders auth step", %{conn: conn} do
      {:ok, _lv, html} = live(conn, "/onboarding/auth")
      assert html =~ "Sign in with email"
      assert html =~ "Send Magic Link"
    end

    test "sends magic link", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/onboarding/auth")

      html =
        lv
        |> form("form", user: %{email: "test@example.com"})
        |> render_submit()

      assert html =~ "Magic link sent"
    end
  end
end

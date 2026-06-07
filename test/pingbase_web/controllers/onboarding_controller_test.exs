defmodule PingbaseWeb.OnboardingControllerTest do
  use PingbaseWeb.ConnCase

  alias Pingbase.Accounts
  alias Pingbase.Accounts.MagicLink

  describe "GET /onboarding/verify" do
    test "verifies valid token and sets session", %{conn: conn} do
      {:ok, user} = Accounts.create_user(%{email: "verify@example.com", name: "Verify"})
      {token, hashed} = MagicLink.generate_token()
      MagicLink.store_token(user, hashed)

      conn = get(conn, "/onboarding/verify?token=#{token}")

      assert redirected_to(conn) == "/onboarding/workspace"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome! Let's create your workspace."

      # Session should contain user_id
      assert get_session(conn, :user_id) == user.id
    end

    test "rejects invalid token", %{conn: conn} do
      conn = get(conn, "/onboarding/verify?token=invalid-token")

      assert redirected_to(conn) == "/onboarding/auth"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid or expired link. Please try again."
      assert is_nil(get_session(conn, :user_id))
    end

    test "rejects expired token", %{conn: conn} do
      {:ok, user} = Accounts.create_user(%{email: "expired@example.com", name: "Expired"})
      {token, hashed} = MagicLink.generate_token()
      MagicLink.store_token(user, hashed)

      # Manually expire the token by updating the user record
      import Ecto.Query
      Pingbase.Repo.update_all(
        from(u in Accounts.User, where: u.id == ^user.id),
        set: [magic_link_expires_at: DateTime.utc_now() |> DateTime.add(-1, :second)]
      )

      conn = get(conn, "/onboarding/verify?token=#{token}")

      assert redirected_to(conn) == "/onboarding/auth"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid or expired link. Please try again."
      assert is_nil(get_session(conn, :user_id))
    end
  end
end

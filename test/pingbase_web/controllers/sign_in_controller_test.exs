defmodule PingbaseWeb.SignInControllerTest do
  use PingbaseWeb.ConnCase

  import Pingbase.AccountsFixtures
  import Pingbase.WorkspacesFixtures

  alias Pingbase.Accounts
  alias Pingbase.Accounts.MagicLink

  describe "GET /sign-in/verify" do
    test "verifies valid token and redirects to workspace for user with workspaces", %{conn: conn} do
      user = user_fixture()
      workspace = workspace_fixture(user: user)
      {token, hashed} = MagicLink.generate_token()
      MagicLink.store_token(user, hashed)

      conn = get(conn, "/sign-in/verify?token=#{token}")

      assert redirected_to(conn) == "/w/#{workspace.slug}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome back!"
      assert get_session(conn, :user_id) == user.id
    end

    test "verifies valid token and redirects to onboarding for user without workspaces", %{conn: conn} do
      user = user_fixture()
      {token, hashed} = MagicLink.generate_token()
      MagicLink.store_token(user, hashed)

      conn = get(conn, "/sign-in/verify?token=#{token}")

      assert redirected_to(conn) == "/onboarding/workspace"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome! Let's create your workspace."
      assert get_session(conn, :user_id) == user.id
    end

    test "rejects invalid token", %{conn: conn} do
      conn = get(conn, "/sign-in/verify?token=invalid-token")

      assert redirected_to(conn) == "/sign-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid or expired link. Please try again."
      assert is_nil(get_session(conn, :user_id))
    end

    test "rejects expired token", %{conn: conn} do
      user = user_fixture()
      {token, hashed} = MagicLink.generate_token()
      MagicLink.store_token(user, hashed)

      # Manually expire the token
      import Ecto.Query
      Pingbase.Repo.update_all(
        from(u in Accounts.User, where: u.id == ^user.id),
        set: [magic_link_expires_at: DateTime.utc_now() |> DateTime.add(-1, :second)]
      )

      conn = get(conn, "/sign-in/verify?token=#{token}")

      assert redirected_to(conn) == "/sign-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid or expired link. Please try again."
      assert is_nil(get_session(conn, :user_id))
    end
  end

  describe "GET /sign-out" do
    test "clears session and redirects to home", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      conn = get(conn, "/sign-out")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Signed out successfully."
      assert is_nil(get_session(conn, :user_id))
    end
  end
end

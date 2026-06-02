defmodule Pingbase.AccountsTest do
  use Pingbase.DataCase

  alias Pingbase.Accounts

  describe "users" do
    alias Pingbase.Accounts.User

    import Pingbase.AccountsFixtures

    @invalid_attrs %{email: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id).id == user.id
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{email: "user@example.com", name: "Test User"}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == "user@example.com"
      assert user.name == "Test User"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{name: "Updated Name"}

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.name == "Updated Name"
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end
  end

  describe "api_tokens" do
    alias Pingbase.Accounts.ApiToken

    import Pingbase.AccountsFixtures

    test "create_api_token/2 creates a token for a user" do
      user = user_fixture()
      assert {:ok, %ApiToken{} = token, raw_token} = Accounts.create_api_token(user, "Test Token")
      assert token.name == "Test Token"
      assert is_binary(raw_token)
    end

    test "validate_api_token/1 returns user for valid token" do
      user = user_fixture()
      {:ok, _token, raw_token} = Accounts.create_api_token(user, "Test Token")

      assert {:ok, %User{} = validated_user} = Accounts.validate_api_token(raw_token)
      assert validated_user.id == user.id
    end

    test "validate_api_token/1 returns error for invalid token" do
      assert :error = Accounts.validate_api_token("invalid-token")
    end
  end
end

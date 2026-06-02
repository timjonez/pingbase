defmodule Pingbase.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pingbase.Accounts` context.
  """

  alias Pingbase.Accounts

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "user#{System.unique_integer()}@example.com",
        name: "Test User"
      })
      |> Accounts.create_user()

    user
  end
end

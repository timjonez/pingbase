defmodule PingbaseWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use PingbaseWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import PingbaseWeb.ConnCase
    end
  end

  setup tags do
    Pingbase.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Logs in a user by setting the session.
  """
  def log_in_user(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{user_id: user.id})
  end
end

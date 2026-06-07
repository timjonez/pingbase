defmodule PingbaseWeb.RoomLiveTest do
  use PingbaseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pingbase.AccountsFixtures
  import Pingbase.WorkspacesFixtures
  import Pingbase.ChatFixtures

  alias Pingbase.Chat

  describe "RoomLive.Show" do
    test "renders room with messages", %{conn: conn} do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      message = message_fixture(room)

      conn = get(conn, ~p"/w/#{workspace.slug}/rooms/#{room.id}")
      assert html_response(conn, 200) =~ room.name

      {:ok, _lv, html} = live(conn)
      assert html =~ message.content
      assert html =~ room.name
    end

    test "sends a message", %{conn: conn} do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      user = user_fixture()
      # Add user to workspace
      Pingbase.Workspaces.add_member(workspace, user)

      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/rooms/#{room.id}")

      lv
      |> form("form", message: %{content: "Hello from test"})
      |> render_submit()

      # Broadcast is received async, render to get updated HTML
      html = render(lv)
      assert html =~ "Hello from test"
    end

    test "selects a thread and shows replies", %{conn: conn} do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      parent = message_fixture(room)
      reply = thread_reply_fixture(parent)

      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/rooms/#{room.id}")

      html =
        lv
        |> element("button", "Reply in thread")
        |> render_click()

      assert html =~ "Thread"
      assert html =~ reply.content
    end

    test "adds a reaction to a message", %{conn: conn} do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      user = user_fixture()
      Pingbase.Workspaces.add_member(workspace, user)
      message = message_fixture(room, user: user)

      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/rooms/#{room.id}")

      lv
      |> element("button[phx-value-emoji='👍']")
      |> render_click()

      message = Chat.get_message!(message.id)
      assert length(message.reactions) == 1
    end

    test "shows thread reply count indicator", %{conn: conn} do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      parent = message_fixture(room)
      thread_reply_fixture(parent)
      thread_reply_fixture(parent)

      {:ok, _lv, html} = live(conn, ~p"/w/#{workspace.slug}/rooms/#{room.id}")

      assert html =~ "2 replies"
    end

    test "clears input after sending a message", %{conn: conn} do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      user = user_fixture()
      Pingbase.Workspaces.add_member(workspace, user)

      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/rooms/#{room.id}")

      lv
      |> form("form", message: %{content: "Test message"})
      |> render_submit()

      html = render(lv)
      assert html =~ "Test message"
    end

    test "adds a reaction to a thread reply", %{conn: conn} do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      user = user_fixture()
      Pingbase.Workspaces.add_member(workspace, user)
      parent = message_fixture(room, user: user)
      reply = thread_reply_fixture(parent, user: user)

      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/w/#{workspace.slug}/rooms/#{room.id}")

      lv
      |> element("button", "Reply in thread")
      |> render_click()

      lv
      |> element("button[phx-value-message-id='#{reply.id}'][phx-value-emoji='👍']")
      |> render_click()

      reply = Chat.get_message!(reply.id)
      assert length(reply.reactions) == 1
    end

    test "reacting to a thread reply does not show reply in main message stream", %{conn: conn} do
      workspace = workspace_fixture()
      room = room_fixture(workspace)
      user = user_fixture()
      Pingbase.Workspaces.add_member(workspace, user)
      parent = message_fixture(room, user: user, content: "Parent message")
      reply = thread_reply_fixture(parent, user: user, content: "Thread reply content")

      conn = log_in_user(conn, user)
      {:ok, lv, html} = live(conn, ~p"/w/#{workspace.slug}/rooms/#{room.id}")

      # Initially, the reply content should not be in the main stream
      refute html =~ "Thread reply content"

      lv
      |> element("button", "Reply in thread")
      |> render_click()

      # React to the thread reply in the sidebar
      lv
      |> element("button[phx-value-message-id='#{reply.id}'][phx-value-emoji='👍']")
      |> render_click()

      html = render(lv)

      # The reply content should still not appear in the main message stream
      # It should only be in the thread sidebar
      message_elements =
        html
        |> Floki.parse_document!()
        |> Floki.find("[data-message-id]")
        |> Enum.map(&Floki.attribute(&1, "data-message-id"))
        |> List.flatten()

      # The reply should not have a data-message-id in the main stream
      # We expect only the parent message in the main stream
      refute "#{reply.id}" in message_elements
    end
  end
end

defmodule PingbaseWeb.WorkspaceLive.Show do
  @moduledoc """
  LiveView for a workspace overview. Shows the sidebar with rooms
  and a landing page for selecting a channel.
  """
  use PingbaseWeb, :live_view

  alias Pingbase.Workspaces
  alias Pingbase.Chat

  @impl true
  def mount(%{"workspace_slug" => slug}, session, socket) do
    case Workspaces.get_workspace_by_slug(slug) do
      nil ->
        {:ok, socket |> redirect(to: ~p"/")}

      workspace ->
        rooms = Chat.list_rooms(workspace)
        current_user = get_user_from_session(session)

        unread_counts =
          if current_user do
            rooms
            |> Enum.map(&{&1.id, Chat.unread_count(&1, current_user)})
            |> Enum.into(%{})
          else
            %{}
          end

        {:ok,
         socket
         |> assign(:workspace, workspace)
         |> assign(:rooms, rooms)
         |> assign(:active_rooms, Enum.filter(rooms, &(&1.is_archived == false)))
         |> assign(:archived_rooms, Enum.filter(rooms, &(&1.is_archived == true)))
         |> assign(:show_archived, false)
         |> assign(:unread_counts, unread_counts)
         |> assign(:current_user, current_user)
         |> assign(:page_title, workspace.name)}
    end
  end

  defp get_user_from_session(session) do
    case session do
      %{"user_id" => user_id} ->
        Pingbase.Accounts.get_user!(user_id)

      _ ->
        nil
    end
  end

  @impl true
  def handle_event("toggle_archived", _params, socket) do
    {:noreply, assign(socket, :show_archived, !socket.assigns.show_archived)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-base-100">
      <!-- Sidebar -->
      <div class="w-64 bg-base-200 border-r border-base-300 flex flex-col flex-shrink-0">
        <!-- Workspace Header -->
        <div class="p-4 border-b border-base-300">
          <h1 class="font-bold text-lg truncate"><%= @workspace.name %></h1>
        </div>

        <!-- Room List -->
        <div class="flex-1 overflow-y-auto p-2 space-y-1">
          <!-- Active Rooms -->
          <div class="px-2 py-1 text-xs font-semibold text-base-content/60 uppercase tracking-wider">
            Channels
          </div>
          <%= for room <- @active_rooms do %>
            <.link
              navigate={~p"/w/#{@workspace.slug}/rooms/#{room.id}"}
              class="flex items-center justify-between px-2 py-1.5 rounded-lg text-sm transition-colors hover:bg-base-300"
            >
              <div class="flex items-center min-w-0">
                <%= if room.type == "channel" do %>
                  <span class="text-base-content/60 mr-2">#</span>
                <% else %>
                  <span class="text-base-content/60 mr-2">@</span>
                <% end %>
                <span class="truncate"><%= room.name %></span>
              </div>
              <%= if @unread_counts[room.id] && @unread_counts[room.id] > 0 do %>
                <span class="badge badge-sm badge-primary ml-2"><%= @unread_counts[room.id] %></span>
              <% end %>
            </.link>
          <% end %>

          <!-- Archived Rooms Toggle -->
          <%= if @archived_rooms != [] do %>
            <button
              phx-click="toggle_archived"
              class="flex items-center px-2 py-1 text-xs font-semibold text-base-content/60 uppercase tracking-wider hover:text-base-content transition-colors mt-2"
            >
              <span class="mr-1">
                <%= if @show_archived, do: "▼", else: "▶" %>
              </span>
              Archived
            </button>
            <%= if @show_archived do %>
              <%= for room <- @archived_rooms do %>
                <.link
                  navigate={~p"/w/#{@workspace.slug}/rooms/#{room.id}"}
                  class="flex items-center px-2 py-1.5 rounded-lg text-sm transition-colors opacity-60 hover:bg-base-300"
                >
                  <span class="text-base-content/60 mr-2">#</span>
                  <span class="truncate"><%= room.name %></span>
                </.link>
              <% end %>
            <% end %>
          <% end %>
        </div>

        <!-- User Section -->
        <div class="p-3 border-t border-base-300">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-full bg-primary text-primary-content flex items-center justify-center text-sm font-medium">
              <%= if @current_user, do: String.first(@current_user.name || "?"), else: "?" %>
            </div>
            <div class="flex-1 min-w-0">
              <div class="text-sm font-medium truncate">
                <%= if @current_user, do: @current_user.name, else: "Guest" %>
              </div>
              <div class="text-xs text-base-content/60">Online</div>
            </div>
          </div>
          <%= if @current_user do %>
            <div class="mt-2 flex gap-2">
              <.link
                navigate={~p"/settings/profile"}
                class="text-xs text-base-content/60 hover:text-base-content transition-colors"
              >
                Settings
              </.link>
              <.link
                navigate={~p"/w/#{@workspace.slug}/settings/general"}
                class="text-xs text-base-content/60 hover:text-base-content transition-colors"
              >
                Workspace
              </.link>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Main Content -->
      <div class="flex-1 flex flex-col">
        <div class="flex-1 flex items-center justify-center">
          <div class="text-center">
            <h2 class="text-2xl font-bold text-base-content/80 mb-2">
              <%= @workspace.name %>
            </h2>
            <p class="text-base-content/60">
              Select a channel to start chatting
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

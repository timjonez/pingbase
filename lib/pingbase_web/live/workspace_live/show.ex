defmodule PingbaseWeb.WorkspaceLive.Show do
  use PingbaseWeb, :live_view

  alias Pingbase.Workspaces

  @impl true
  def mount(%{"workspace_slug" => slug}, _session, socket) do
    case Workspaces.get_workspace_by_slug(slug) do
      nil ->
        {:ok, socket |> redirect(to: "/")}

      workspace ->
        rooms = Pingbase.Chat.list_rooms(workspace)

        {:ok,
         socket
         |> assign(:workspace, workspace)
         |> assign(:rooms, rooms)
         |> assign(:page_title, workspace.name)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-base-100">
      <!-- Sidebar -->
      <div class="w-64 bg-base-200 border-r border-base-300 flex flex-col">
        <!-- Workspace Header -->
        <div class="p-4 border-b border-base-300">
          <h1 class="font-bold text-lg truncate"><%= @workspace.name %></h1>
        </div>

        <!-- Room List -->
        <div class="flex-1 overflow-y-auto p-2 space-y-1">
          <div class="px-2 py-1 text-xs font-semibold text-base-content/60 uppercase tracking-wider">
            Channels
          </div>
          <%= for room <- @rooms do %>
            <.link
              navigate={~p"/w/#{@workspace.slug}/rooms/#{room.id}"}
              class={[
                "flex items-center px-2 py-1.5 rounded-lg text-sm transition-colors",
                if(room.type == "channel", do: "hover:bg-base-300", else: "")
              ]}
            >
              <%= if room.type == "channel" do %>
                <span class="text-base-content/60 mr-2">#</span>
              <% else %>
                <span class="text-base-content/60 mr-2">@</span>
              <% end %>
              <span class="truncate"><%= room.name %></span>
            </.link>
          <% end %>
        </div>

        <!-- User Section -->
        <div class="p-3 border-t border-base-300">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-full bg-primary text-primary-content flex items-center justify-center text-sm font-medium">
              U
            </div>
            <div class="flex-1 min-w-0">
              <div class="text-sm font-medium truncate">User</div>
              <div class="text-xs text-base-content/60">Online</div>
            </div>
          </div>
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

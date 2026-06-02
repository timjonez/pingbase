defmodule PingbaseWeb.RoomLive.Show do
  use PingbaseWeb, :live_view

  alias Pingbase.Chat
  alias Pingbase.Workspaces

  @impl true
  def mount(%{"workspace_slug" => slug, "room_id" => room_id}, _session, socket) do
    case Workspaces.get_workspace_by_slug(slug) do
      nil ->
        {:ok, socket |> redirect(to: "/")}

      workspace ->
        room = Chat.get_room!(room_id)
        messages = Chat.list_messages(room, limit: 50)
        rooms = Chat.list_rooms(workspace)

        {:ok,
         socket
         |> assign(:workspace, workspace)
         |> assign(:room, room)
         |> assign(:messages, messages)
         |> assign(:rooms, rooms)
         |> assign(:page_title, "#{room.name} · #{workspace.name}")}
    end
  end

  @impl true
  def handle_event("send", %{"message" => %{"content" => content}}, socket) do
    # In a real app, this would create a message via the Chat context
    # and broadcast to PubSub. For now, we'll just push to the list.
    {:noreply, socket}
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
                if(room.id == @room.id, do: "bg-primary/10 text-primary", else: "hover:bg-base-300")
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

      <!-- Chat Area -->
      <div class="flex-1 flex flex-col">
        <!-- Room Header -->
        <div class="h-14 border-b border-base-300 flex items-center px-4">
          <div>
            <h2 class="font-semibold text-base-content"><%= @room.name %></h2>
            <%= if @room.topic do %>
              <p class="text-xs text-base-content/60"><%= @room.topic %></p>
            <% end %>
          </div>
        </div>

        <!-- Messages -->
        <div class="flex-1 overflow-y-auto p-4 space-y-4">
          <%= for message <- @messages do %>
            <div class="flex gap-3">
              <div class="w-8 h-8 rounded-full bg-secondary text-secondary-content flex-shrink-0 flex items-center justify-center text-sm font-medium">
                <%= String.first(message.user.name || "U") %>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-baseline gap-2">
                  <span class="font-semibold text-sm text-base-content"><%= message.user.name %></span>
                  <span class="text-xs text-base-content/40">
                    <%= Calendar.strftime(message.inserted_at, "%H:%M") %>
                  </span>
                </div>
                <p class="text-sm text-base-content/90 mt-0.5"><%= message.content %></p>
              </div>
            </div>
          <% end %>
        </div>

        <!-- Input -->
        <div class="p-4 border-t border-base-300">
          <form phx-submit="send" class="flex gap-2">
            <input
              type="text"
              name="message[content]"
              placeholder="Type a message..."
              class="flex-1 input input-bordered"
              autocomplete="off"
            />
            <button type="submit" class="btn btn-primary">Send</button>
          </form>
        </div>
      </div>
    </div>
    """
  end
end

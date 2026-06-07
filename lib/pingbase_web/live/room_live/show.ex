defmodule PingbaseWeb.RoomLive.Show do
  @moduledoc """
  LiveView for a chat room. Shows messages, thread sidebar, typing indicators,
  and supports real-time messaging via PubSub.
  """
  use PingbaseWeb, :live_view

  alias Pingbase.Chat
  alias Pingbase.Workspaces
  alias Pingbase.Notifications

  @typing_timeout_ms 3_000
  @infinite_scroll_limit 50

  @impl true
  def mount(%{"workspace_slug" => slug, "room_id" => room_id}, session, socket) do
    case Workspaces.get_workspace_by_slug(slug) do
      nil ->
        {:ok, socket |> redirect(to: ~p"/")}

      workspace ->
        room = Chat.get_room!(room_id)
        messages = Chat.list_messages(room, limit: @infinite_scroll_limit)
        rooms = Chat.list_rooms(workspace)

        # Subscribe to room messages and typing
        Phoenix.PubSub.subscribe(Pingbase.PubSub, "room:#{room.id}")
        Phoenix.PubSub.subscribe(Pingbase.PubSub, "room:#{room.id}:typing")

        # Get current user from session
        current_user = get_user_from_session(session)

        # Get unread counts per room
        unread_counts =
          if current_user do
            rooms
            |> Enum.map(&{&1.id, Chat.unread_count(&1, current_user)})
            |> Enum.into(%{})
          else
            %{}
          end

        # Get thread messages if viewing a thread
        selected_message = nil
        thread_messages = []

        # Update last read for this room
        if current_user && messages != [] do
          latest_message = List.first(messages)
          Chat.update_last_read(room, current_user, latest_message.id)
        end

        {:ok,
         socket
         |> assign(:workspace, workspace)
         |> assign(:room, room)
         |> assign(:rooms, rooms)
         |> assign(:active_rooms, Enum.filter(rooms, &(&1.is_archived == false)))
         |> assign(:archived_rooms, Enum.filter(rooms, &(&1.is_archived == true)))
         |> assign(:show_archived, false)
         |> assign(:selected_message, selected_message)
         |> assign(:thread_messages, thread_messages)
         |> assign(:page_title, "##{room.name} · #{workspace.name}")
         |> assign(:typing_users, [])
         |> assign(:unread_counts, unread_counts)
         |> assign(:current_user, current_user)
         |> stream(:messages, messages, dom_id: &"message-#{&1.id}")
         |> assign(:has_more_messages, length(messages) == @infinite_scroll_limit)
         |> assign(:replying_to, nil)}
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
  def handle_event("send", %{"message" => %{"content" => content}}, socket) do
    room = socket.assigns.room
    current_user = socket.assigns.current_user

    if current_user do
      case Chat.send_message(room, current_user, %{"content" => content, "parent_id" => socket.assigns[:replying_to]}) do
        {:ok, message} ->
          # If replying, also broadcast to thread
          if socket.assigns[:replying_to] do
            Phoenix.PubSub.broadcast(
              Pingbase.PubSub,
              "room:#{room.id}:thread:#{socket.assigns[:replying_to]}",
              {:new_thread_message, message}
            )

            # Notify parent message author
            parent = Chat.get_message!(socket.assigns[:replying_to])
            Notifications.notify_thread_reply(message, parent)
          end

          {:noreply,
           socket
           |> assign(:replying_to, socket.assigns[:replying_to])
           |> push_event("clear_input", %{})}

        {:error, _changeset} ->
          {:noreply, socket |> put_flash(:error, "Failed to send message")}
      end
    else
      {:noreply, socket |> put_flash(:error, "You must be logged in to send messages")}
    end
  end

  @impl true
  def handle_event("typing", _params, socket) do
    if socket.assigns[:current_user] do
      Chat.broadcast_typing(socket.assigns.room, socket.assigns.current_user)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_thread", %{"message-id" => message_id}, socket) do
    message = Chat.get_message!(message_id)
    thread_messages = Chat.list_thread_messages(message)

    # Subscribe to thread updates
    Phoenix.PubSub.subscribe(Pingbase.PubSub, "room:#{socket.assigns.room.id}:thread:#{message.id}")

    {:noreply,
     socket
     |> assign(:selected_message, message)
     |> assign(:thread_messages, thread_messages)
     |> assign(:replying_to, message.id)}
  end

  @impl true
  def handle_event("close_thread", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_message, nil)
     |> assign(:thread_messages, [])
     |> assign(:replying_to, nil)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    room = socket.assigns.room
    oldest_message = socket.assigns.streams.messages |> Enum.to_list() |> List.first()

    if oldest_message do
      more_messages = Chat.list_messages(room, limit: @infinite_scroll_limit, before_id: oldest_message.id)

      {:noreply,
       socket
       |> stream(:messages, more_messages, at: 0)
       |> assign(:has_more_messages, length(more_messages) == @infinite_scroll_limit)}
    else
      {:noreply, socket |> assign(:has_more_messages, false)}
    end
  end

  @impl true
  def handle_event("add_reaction", %{"emoji" => emoji, "message-id" => message_id}, socket) do
    message = Chat.get_message!(message_id)
    current_user = socket.assigns.current_user

    if current_user do
      case Chat.add_reaction(message, current_user, emoji) do
        {:ok, _reaction} ->
          # Broadcast reaction update
          Phoenix.PubSub.broadcast(
            Pingbase.PubSub,
            "room:#{socket.assigns.room.id}",
            {:reaction_added, message_id, emoji, current_user.id}
          )

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_archived", _params, socket) do
    {:noreply, assign(socket, :show_archived, !socket.assigns.show_archived)}
  end

  @impl true
  def handle_event("edit_message", %{"message-id" => message_id, "content" => content}, socket) do
    message = Chat.get_message!(message_id)
    current_user = socket.assigns.current_user

    if current_user && message.user_id == current_user.id do
      case Chat.update_message(message, %{"content" => content, "edited_at" => DateTime.utc_now() |> DateTime.truncate(:second)}) do
        {:ok, updated_message} ->
          Phoenix.PubSub.broadcast(
            Pingbase.PubSub,
            "room:#{socket.assigns.room.id}",
            {:message_edited, updated_message}
          )

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, socket |> put_flash(:error, "Failed to edit message")}
      end
    else
      {:noreply, socket |> put_flash(:error, "You can only edit your own messages")}
    end
  end

  ## PubSub handlers

  @impl true
  def handle_info({:new_message, message}, socket) do
    # Only append if it's a top-level message (not a thread reply)
    if is_nil(message.parent_id) do
      {:noreply,
       socket
       |> stream_insert(:messages, message, at: -1)
       |> push_event("scroll_bottom", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:thread_reply, parent_id, reply_count}, socket) do
    message = Chat.get_message!(parent_id)
    message = %{message | reply_count: reply_count}
    {:noreply, stream_insert(socket, :messages, message)}
  end

  @impl true
  def handle_info({:new_thread_message, message}, socket) do
    if socket.assigns.selected_message && message.parent_id == socket.assigns.selected_message.id do
      {:noreply, assign(socket, :thread_messages, socket.assigns.thread_messages ++ [message])}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:typing, %{user_id: user_id, user_name: user_name}}, socket) do
    # Ignore our own typing events
    if user_id == socket.assigns.current_user.id do
      {:noreply, socket}
    else
      # Add user to typing list, schedule removal
      typing_users = socket.assigns.typing_users

      if Enum.find(typing_users, &(&1.user_id == user_id)) do
        {:noreply, socket}
      else
        Process.send_after(self(), {:remove_typing, user_id}, @typing_timeout_ms)

        {:noreply,
         assign(socket, :typing_users, [%{user_id: user_id, user_name: user_name} | typing_users])}
      end
    end
  end

  @impl true
  def handle_info({:remove_typing, user_id}, socket) do
    typing_users = Enum.reject(socket.assigns.typing_users, &(&1.user_id == user_id))
    {:noreply, assign(socket, :typing_users, typing_users)}
  end

  @impl true
  def handle_info({:reaction_added, message_id, _emoji, _user_id}, socket) do
    message = Chat.get_message!(message_id)

    # Only update main stream for top-level messages
    socket =
      if is_nil(message.parent_id) do
        stream_insert(socket, :messages, message)
      else
        socket
      end

    # If the reacted message is the selected parent, refresh it
    socket =
      if socket.assigns.selected_message && socket.assigns.selected_message.id == message_id do
        assign(socket, :selected_message, message)
      else
        socket
      end

    # If the reacted message is in the current thread, refresh thread messages
    socket =
      if socket.assigns.selected_message && message.parent_id == socket.assigns.selected_message.id do
        thread_messages = Chat.list_thread_messages(socket.assigns.selected_message)
        assign(socket, :thread_messages, thread_messages)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_edited, message}, socket) do
    socket =
      if is_nil(message.parent_id) do
        stream_insert(socket, :messages, message)
      else
        socket
      end

    {:noreply, socket}
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
              class={[
                "flex items-center justify-between px-2 py-1.5 rounded-lg text-sm transition-colors",
                if(room.id == @room.id, do: "bg-primary/10 text-primary", else: "hover:bg-base-300")
              ]}
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
                  class={[
                    "flex items-center px-2 py-1.5 rounded-lg text-sm transition-colors opacity-60",
                    if(room.id == @room.id, do: "bg-primary/10 text-primary", else: "hover:bg-base-300")
                  ]}
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

      <!-- Chat Area -->
      <div class="flex-1 flex flex-col min-w-0">
        <!-- Room Header -->
        <div class="h-14 border-b border-base-300 flex items-center px-4 flex-shrink-0">
          <div>
            <h2 class="font-semibold text-base-content">
              <%= if @room.type == "channel", do: "##{@room.name}", else: @room.name %>
            </h2>
            <%= if @room.topic do %>
              <p class="text-xs text-base-content/60"><%= @room.topic %></p>
            <% end %>
          </div>
        </div>

        <!-- Messages -->
        <div
          id="messages-container"
          class="flex-1 overflow-y-auto p-4 space-y-4"
          phx-viewport-top={if @has_more_messages, do: "load_more"}
          phx-hook="ScrollBottom"
        >
          <div id="messages" phx-update="stream" class="space-y-4">
            <%= for {dom_id, message} <- @streams.messages do %>
              <div
                id={dom_id}
                class="flex flex-col hover:bg-base-200/50 p-2 -mx-2 rounded-lg transition-colors"
                data-message-id={message.id}
              >
                <div class="flex gap-3 group">
                  <div class="w-8 h-8 rounded-full bg-secondary text-secondary-content flex-shrink-0 flex items-center justify-center text-sm font-medium cursor-pointer"
                    phx-click="select_thread"
                    phx-value-message-id={message.id}
                  >
                    <%= String.first(message.user.name || "?") %>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-baseline gap-2">
                      <span class="font-semibold text-sm text-base-content"><%= message.user.name %></span>
                      <span class="text-xs text-base-content/40">
                        <%= Calendar.strftime(message.inserted_at, "%H:%M") %>
                      </span>
                      <%= if message.edited_at do %>
                        <span class="text-xs text-base-content/40">(edited)</span>
                      <% end %>
                    </div>
                    <p class="text-sm text-base-content/90 mt-0.5"><%= message.content %></p>

                    <!-- Reactions -->
                    <%= if message.reactions != [] do %>
                      <div class="flex gap-1 mt-1 flex-wrap">
                        <%= for {emoji, count} <- Enum.frequencies_by(message.reactions, & &1.emoji) do %>
                          <button
                            class="badge badge-sm gap-1 hover:bg-primary/20 transition-colors"
                            phx-click="add_reaction"
                            phx-value-emoji={emoji}
                            phx-value-message-id={message.id}
                          >
                            <%= emoji %> <%= count %>
                          </button>
                        <% end %>
                      </div>
                    <% end %>

                    <!-- Reaction + Reply actions -->
                    <div class="flex gap-2 mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <%= for emoji <- ["👍", "❤️", "😂", "🎉"] do %>
                        <button
                          class="text-sm hover:scale-125 transition-transform"
                          phx-click="add_reaction"
                          phx-value-emoji={emoji}
                          phx-value-message-id={message.id}
                        >
                          <%= emoji %>
                        </button>
                      <% end %>
                      <button
                        class="text-xs text-base-content/60 hover:text-base-content"
                        phx-click="select_thread"
                        phx-value-message-id={message.id}
                      >
                        Reply in thread
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Thread indicator -->
                <%= if message.reply_count && message.reply_count > 0 do %>
                  <div class="pl-11 mt-1">
                    <button
                      class="flex items-center gap-1 text-xs text-base-content/60 hover:text-primary transition-colors"
                      phx-click="select_thread"
                      phx-value-message-id={message.id}
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                      </svg>
                      <%= message.reply_count %> <%= if message.reply_count == 1, do: "reply", else: "replies" %>
                    </button>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Typing Indicator -->
        <%= if @typing_users != [] do %>
          <div class="px-4 py-2 text-xs text-base-content/60 flex items-center gap-1">
            <%= names = Enum.map(@typing_users, & &1.user_name) |> Enum.join(", ") %>
            <%= if length(@typing_users) == 1, do: "#{names} is typing...", else: "#{names} are typing..." %>
            <span class="inline-flex gap-0.5">
              <span class="w-1 h-1 rounded-full bg-base-content/60 animate-bounce" style="animation-delay: 0ms"></span>
              <span class="w-1 h-1 rounded-full bg-base-content/60 animate-bounce" style="animation-delay: 150ms"></span>
              <span class="w-1 h-1 rounded-full bg-base-content/60 animate-bounce" style="animation-delay: 300ms"></span>
            </span>
          </div>
        <% end %>

        <!-- Input -->
        <div class="p-4 border-t border-base-300 flex-shrink-0">
          <%= if @replying_to do %>
            <div class="flex items-center justify-between px-3 py-2 mb-2 bg-base-200 rounded-lg text-sm">
              <span class="text-base-content/60">Replying to thread</span>
              <button phx-click="close_thread" class="text-base-content/60 hover:text-base-content">
                ✕
              </button>
            </div>
          <% end %>
          <form phx-submit="send" phx-change="typing" class="flex gap-2 items-end">
            <textarea
              id="message-input"
              name="message[content]"
              placeholder={if @replying_to, do: "Reply in thread...", else: "Type a message..."}
              class="flex-1 textarea textarea-bordered resize-none min-h-[2.5rem] max-h-40"
              rows="1"
              autocomplete="off"
              phx-hook="MessageInput"
            ></textarea>
            <button type="submit" class="btn btn-primary">
              <%= if @replying_to, do: "Reply", else: "Send" %>
            </button>
          </form>
        </div>
      </div>

      <!-- Thread Sidebar -->
      <%= if @selected_message do %>
        <div class="w-80 bg-base-200 border-l border-base-300 flex flex-col flex-shrink-0">
          <!-- Thread Header -->
          <div class="h-14 border-b border-base-300 flex items-center justify-between px-4 flex-shrink-0">
            <h3 class="font-semibold text-sm">Thread</h3>
            <button phx-click="close_thread" class="text-base-content/60 hover:text-base-content">
              ✕
            </button>
          </div>

          <!-- Parent Message -->
          <div class="p-4 border-b border-base-300">
            <div class="flex gap-3 group">
              <div class="w-8 h-8 rounded-full bg-secondary text-secondary-content flex-shrink-0 flex items-center justify-center text-sm font-medium">
                <%= String.first(@selected_message.user.name || "?") %>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-baseline gap-2">
                  <span class="font-semibold text-sm text-base-content"><%= @selected_message.user.name %></span>
                  <span class="text-xs text-base-content/40">
                    <%= Calendar.strftime(@selected_message.inserted_at, "%H:%M") %>
                  </span>
                </div>
                <p class="text-sm text-base-content/90 mt-0.5"><%= @selected_message.content %></p>

                <!-- Reactions -->
                <%= if @selected_message.reactions != [] do %>
                  <div class="flex gap-1 mt-1 flex-wrap">
                    <%= for {emoji, count} <- Enum.frequencies_by(@selected_message.reactions, & &1.emoji) do %>
                      <button
                        class="badge badge-sm gap-1 hover:bg-primary/20 transition-colors"
                        phx-click="add_reaction"
                        phx-value-emoji={emoji}
                        phx-value-message-id={@selected_message.id}
                      >
                        <%= emoji %> <%= count %>
                      </button>
                    <% end %>
                  </div>
                <% end %>

                <!-- Reaction actions -->
                <div class="flex gap-2 mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <%= for emoji <- ["👍", "❤️", "😂", "🎉"] do %>
                    <button
                      class="text-sm hover:scale-125 transition-transform"
                      phx-click="add_reaction"
                      phx-value-emoji={emoji}
                      phx-value-message-id={@selected_message.id}
                    >
                      <%= emoji %>
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <!-- Thread Replies -->
          <div class="flex-1 overflow-y-auto p-4 space-y-3">
            <%= if @thread_messages == [] do %>
              <p class="text-sm text-base-content/60 text-center">No replies yet</p>
            <% else %>
              <%= for message <- @thread_messages do %>
                <div class="flex gap-3 group">
                  <div class="w-8 h-8 rounded-full bg-secondary text-secondary-content flex-shrink-0 flex items-center justify-center text-sm font-medium">
                    <%= String.first(message.user.name || "?") %>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-baseline gap-2">
                      <span class="font-semibold text-sm text-base-content"><%= message.user.name %></span>
                      <span class="text-xs text-base-content/40">
                        <%= Calendar.strftime(message.inserted_at, "%H:%M") %>
                      </span>
                    </div>
                    <p class="text-sm text-base-content/90 mt-0.5"><%= message.content %></p>

                    <!-- Reactions -->
                    <%= if message.reactions != [] do %>
                      <div class="flex gap-1 mt-1 flex-wrap">
                        <%= for {emoji, count} <- Enum.frequencies_by(message.reactions, & &1.emoji) do %>
                          <button
                            class="badge badge-sm gap-1 hover:bg-primary/20 transition-colors"
                            phx-click="add_reaction"
                            phx-value-emoji={emoji}
                            phx-value-message-id={message.id}
                          >
                            <%= emoji %> <%= count %>
                          </button>
                        <% end %>
                      </div>
                    <% end %>

                    <!-- Reaction actions -->
                    <div class="flex gap-2 mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <%= for emoji <- ["👍", "❤️", "😂", "🎉"] do %>
                        <button
                          class="text-sm hover:scale-125 transition-transform"
                          phx-click="add_reaction"
                          phx-value-emoji={emoji}
                          phx-value-message-id={message.id}
                        >
                          <%= emoji %>
                        </button>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>

          <!-- Thread Input -->
          <div class="p-4 border-t border-base-300 flex-shrink-0">
            <form phx-submit="send" phx-change="typing" class="flex gap-2 items-end">
              <textarea
                id="thread-input"
                name="message[content]"
                placeholder="Reply in thread..."
                class="flex-1 textarea textarea-bordered textarea-sm resize-none min-h-[2rem] max-h-32"
                rows="1"
                autocomplete="off"
                phx-hook="MessageInput"
              ></textarea>
              <button type="submit" class="btn btn-primary btn-sm">Reply</button>
            </form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end

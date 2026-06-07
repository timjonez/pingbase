defmodule PingbaseWeb.WorkspaceSettingsLive.Integrations do
  @moduledoc """
  LiveView for managing workspace integrations (admin only).
  """
  use PingbaseWeb, :live_view

  alias Pingbase.Workspaces
  alias Pingbase.Integrations
  alias Pingbase.Chat

  on_mount {PingbaseWeb.UserAuth, :require_user}

  @impl true
  def mount(%{"workspace_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user

    case Workspaces.get_workspace_by_slug(slug) do
      nil ->
        {:ok, socket |> redirect(to: ~p"/")}

      workspace ->
        membership = Workspaces.get_membership(user, workspace)

        if membership == nil or membership.role not in ["owner", "admin"] do
          {:ok, socket |> redirect(to: ~p"/w/#{slug}")}
        else
          rooms = Chat.list_rooms(workspace)

          {:ok,
           socket
           |> assign(:workspace, workspace)
           |> assign(:membership, membership)
           |> assign(:rooms, rooms)
           |> assign(:page_title, "Integrations · #{workspace.name}")
           |> assign(:incoming_webhook_name, "")
           |> assign(:incoming_webhook_room_id, "")
           |> assign(:slash_command, "")
           |> assign(:slash_command_url, "")}
        end
    end
  end

  @impl true
  def handle_event("create_incoming_webhook", %{"webhook" => %{"name" => name, "room_id" => room_id}}, socket) do
    workspace = socket.assigns.workspace

    attrs = %{
      name: name,
      workspace_id: workspace.id,
      room_id: String.to_integer(room_id),
      token: :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
    }

    case Integrations.create_incoming_webhook(attrs) do
      {:ok, _webhook} ->
        {:noreply,
         socket
         |> assign(:incoming_webhook_name, "")
         |> assign(:incoming_webhook_room_id, "")
         |> put_flash(:info, "Incoming webhook created.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to create webhook.")}
    end
  end

  @impl true
  def handle_event("create_slash_command", %{"command" => %{"command" => command, "url" => url}}, socket) do
    workspace = socket.assigns.workspace

    attrs = %{
      command: command,
      workspace_id: workspace.id,
      url: url,
      token: :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
    }

    case Integrations.create_slash_command(attrs) do
      {:ok, _cmd} ->
        {:noreply,
         socket
         |> assign(:slash_command, "")
         |> assign(:slash_command_url, "")
         |> put_flash(:info, "Slash command created.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to create slash command.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-base-100">
      <!-- Workspace Sidebar -->
      <PingbaseWeb.SettingsComponents.workspace_sidebar workspace={@workspace} rooms={@rooms} current_user={@current_user} />

      <!-- Settings Content -->
      <div class="flex-1 overflow-y-auto">
        <div class="max-w-3xl mx-auto p-4 md:p-8">
          <div class="flex flex-col md:flex-row gap-8">
            <PingbaseWeb.SettingsComponents.settings_nav
              active={:workspace_integrations}
              workspace={@workspace}
              membership={@membership}
            />

            <PingbaseWeb.SettingsComponents.settings_panel>
              <h1 class="text-2xl font-bold text-base-content mb-6">Integrations</h1>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Incoming Webhooks"
                description="Create webhooks to post messages from external services."
              >
                <form phx-submit="create_incoming_webhook" class="space-y-3">
                  <div class="flex gap-3">
                    <input
                      type="text"
                      name="webhook[name]"
                      value={@incoming_webhook_name}
                      placeholder="Webhook name"
                      class="input input-bordered flex-1"
                      required
                    />
                    <select
                      name="webhook[room_id]"
                      class="select select-bordered"
                      required
                    >
                      <option value="">Select channel</option>
                      <%= for room <- @rooms do %>
                        <%= if room.type == "channel" && not room.is_archived do %>
                          <option value={room.id} selected={@incoming_webhook_room_id == to_string(room.id)}>#<%= room.name %></option>
                        <% end %>
                      <% end %>
                    </select>
                    <button type="submit" class="btn btn-primary">Create</button>
                  </div>
                </form>

                <div class="mt-4 p-3 bg-base-200 rounded-lg text-sm text-base-content/60">
                  <p>POST to <code class="font-mono bg-base-300 px-1 rounded">/api/webhooks/incoming/:token</code></p>
                </div>
              </PingbaseWeb.SettingsComponents.settings_section>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Slash Commands"
                description="Add custom slash commands for your workspace."
              >
                <form phx-submit="create_slash_command" class="space-y-3">
                  <div class="flex gap-3">
                    <input
                      type="text"
                      name="command[command]"
                      value={@slash_command}
                      placeholder="/command"
                      class="input input-bordered flex-1"
                      required
                    />
                    <input
                      type="url"
                      name="command[url]"
                      value={@slash_command_url}
                      placeholder="https://..."
                      class="input input-bordered flex-1"
                      required
                    />
                    <button type="submit" class="btn btn-primary">Add</button>
                  </div>
                </form>
              </PingbaseWeb.SettingsComponents.settings_section>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Outgoing Webhooks"
                description="Send events to external URLs."
              >
                <p class="text-sm text-base-content/60">
                  Outgoing webhook management coming soon. For now, configure outgoing webhooks via the API.
                </p>
              </PingbaseWeb.SettingsComponents.settings_section>
            </PingbaseWeb.SettingsComponents.settings_panel>
          </div>
        </div>
      </div>
    </div>
    """
  end

end

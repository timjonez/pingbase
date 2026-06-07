defmodule PingbaseWeb.WorkspaceSettingsLive.Notifications do
  @moduledoc """
  LiveView for managing workspace notification preferences.
  """
  use PingbaseWeb, :live_view

  alias Pingbase.Workspaces
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

        if membership == nil do
          {:ok, socket |> redirect(to: ~p"/")}
        else
          rooms = Chat.list_rooms(workspace)
          room_memberships = Chat.list_user_room_memberships(user)

          room_prefs =
            room_memberships
            |> Enum.filter(&(&1.room.workspace_id == workspace.id))
            |> Enum.map(&{&1.room_id, &1})
            |> Enum.into(%{})

          {:ok,
           socket
           |> assign(:workspace, workspace)
           |> assign(:membership, membership)
           |> assign(:rooms, rooms)
           |> assign(:room_prefs, room_prefs)
           |> assign(:page_title, "Notifications · #{workspace.name}")}
        end
    end
  end

  @impl true
  def handle_event("update_workspace_pref", %{"notification_pref" => pref}, socket) do
    membership = socket.assigns.membership

    case Workspaces.update_membership(membership, %{notification_pref: pref}) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:membership, updated)
         |> put_flash(:info, "Notification preference updated.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update preference.")}
    end
  end

  @impl true
  def handle_event("update_room_pref", %{"room_id" => room_id, "notification_level" => level}, socket) do
    user = socket.assigns.current_user
    room = Chat.get_room!(String.to_integer(room_id))

    membership = Chat.get_room_membership(room, user)

    result =
      if membership do
        Chat.update_room_membership(membership, %{notification_level: level})
      else
        # Create membership with the preferred level
        %Chat.RoomMembership{}
        |> Chat.RoomMembership.changeset(%{
          room_id: room.id,
          user_id: user.id,
          notification_level: level
        })
        |> Pingbase.Repo.insert()
      end

    case result do
      {:ok, _updated} ->
        room_memberships = Chat.list_user_room_memberships(user)

        room_prefs =
          room_memberships
          |> Enum.filter(&(&1.room.workspace_id == socket.assigns.workspace.id))
          |> Enum.map(&{&1.room_id, &1})
          |> Enum.into(%{})

        {:noreply,
         socket
         |> assign(:room_prefs, room_prefs)
         |> put_flash(:info, "Room notification preference updated.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update room preference.")}
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
              active={:workspace_notifications}
              workspace={@workspace}
              membership={@membership}
            />

            <PingbaseWeb.SettingsComponents.settings_panel>
              <h1 class="text-2xl font-bold text-base-content mb-6">Notifications</h1>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Workspace Notifications"
                description="Default notification behavior for this workspace."
              >
                <form phx-submit="update_workspace_pref">
                  <div class="space-y-3">
                    <%= for {label, value} <- [{"All messages", "all"}, {"Mentions only", "mentions"}, {"Nothing", "none"}] do %>
                      <label class="flex items-center gap-3 p-3 rounded-lg border border-base-300 cursor-pointer hover:bg-base-200/50 transition-colors">
                        <input
                          type="radio"
                          name="notification_pref"
                          value={value}
                          checked={@membership.notification_pref == value}
                          class="radio radio-primary"
                        />
                        <div>
                          <div class="font-medium text-sm"><%= label %></div>
                        </div>
                      </label>
                    <% end %>
                  </div>
                  <button type="submit" class="btn btn-primary mt-4">Save Preference</button>
                </form>
              </PingbaseWeb.SettingsComponents.settings_section>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Per-Room Overrides"
                description="Customize notifications for specific channels."
              >
                <div class="divide-y divide-base-200">
                  <%= for room <- @rooms do %>
                    <%= if room.type == "channel" && not room.is_archived do %>
                      <% rm = @room_prefs[room.id] %>
                      <div class="flex items-center justify-between py-3">
                        <div class="flex items-center gap-2">
                          <span class="text-base-content/60">#</span>
                          <span class="font-medium text-sm"><%= room.name %></span>
                        </div>
                        <form phx-submit="update_room_pref" class="flex items-center gap-2">
                          <input type="hidden" name="room_id" value={room.id} />
                          <select name="notification_level" class="select select-bordered select-sm">
                            <option value="all" selected={is_nil(rm) || rm.notification_level == "all"}>All</option>
                            <option value="mentions" selected={rm && rm.notification_level == "mentions"}>Mentions</option>
                            <option value="none" selected={rm && rm.notification_level == "none"}>Mute</option>
                          </select>
                          <button type="submit" class="btn btn-ghost btn-sm">Save</button>
                        </form>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </PingbaseWeb.SettingsComponents.settings_section>
            </PingbaseWeb.SettingsComponents.settings_panel>
          </div>
        </div>
      </div>
    </div>
    """
  end

end

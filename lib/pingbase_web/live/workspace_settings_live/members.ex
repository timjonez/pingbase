defmodule PingbaseWeb.WorkspaceSettingsLive.Members do
  @moduledoc """
  LiveView for managing workspace members and invites.
  """
  use PingbaseWeb, :live_view

  alias Pingbase.Workspaces
  alias Pingbase.Accounts
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
          load_data(socket, workspace, membership)
        end
    end
  end

  defp load_data(socket, workspace, membership) do
    rooms = Chat.list_rooms(workspace)
    members = Workspaces.list_workspace_memberships(workspace)
    invites = Workspaces.list_workspace_invites(workspace)

    {:ok,
     socket
     |> assign(:workspace, workspace)
     |> assign(:membership, membership)
     |> assign(:rooms, rooms)
     |> assign(:members, members)
     |> assign(:invites, invites)
     |> assign(:page_title, "Members · #{workspace.name}")
     |> assign(:invite_email, "")
     |> assign(:editing_role, nil)}
  end

  @impl true
  def handle_event("send_invite", %{"invite" => %{"email" => email}}, socket) do
    workspace = socket.assigns.workspace
    user = socket.assigns.current_user
    membership = socket.assigns.membership

    if membership.role in ["owner", "admin"] do
      case Workspaces.create_invite(workspace, user, email) do
        {:ok, _invite} ->
          invites = Workspaces.list_workspace_invites(workspace)

          {:noreply,
           socket
           |> assign(:invites, invites)
           |> assign(:invite_email, "")
           |> put_flash(:info, "Invite sent to #{email}.")}

        {:error, changeset} ->
          errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
          email_error = List.first(errors[:email] || ["Failed to send invite"])
          {:noreply, put_flash(socket, :error, email_error)}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to send invites.")}
    end
  end

  @impl true
  def handle_event("cancel_invite", %{"id" => id}, socket) do
    workspace = socket.assigns.workspace
    membership = socket.assigns.membership

    if membership.role in ["owner", "admin"] do
      invite = Enum.find(socket.assigns.invites, &(&1.id == String.to_integer(id)))

      if invite do
        Workspaces.cancel_invite(invite)
        invites = Workspaces.list_workspace_invites(workspace)
        {:noreply, assign(socket, :invites, invites)}
      else
        {:noreply, socket}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to cancel invites.")}
    end
  end

  @impl true
  def handle_event("remove_member", %{"user_id" => user_id}, socket) do
    workspace = socket.assigns.workspace
    membership = socket.assigns.membership
    current_user = socket.assigns.current_user

    if membership.role in ["owner", "admin"] do
      target_user = Accounts.get_user!(String.to_integer(user_id))

      # Don't allow removing yourself if you're the owner
      if target_user.id == current_user.id && membership.role == "owner" do
        {:noreply, put_flash(socket, :error, "You cannot remove yourself as the owner.")}
      else
        Workspaces.remove_member(workspace, target_user)
        members = Workspaces.list_workspace_memberships(workspace)
        {:noreply, assign(socket, :members, members)}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to remove members.")}
    end
  end

  @impl true
  def handle_event("update_role", %{"user_id" => user_id, "role" => role}, socket) do
    workspace = socket.assigns.workspace
    membership = socket.assigns.membership

    if membership.role == "owner" do
      target_user = Accounts.get_user!(String.to_integer(user_id))
      target_membership = Workspaces.get_membership(target_user, workspace)

      case Workspaces.update_membership(target_membership, %{role: role}) do
        {:ok, _} ->
          members = Workspaces.list_workspace_memberships(workspace)
          {:noreply, assign(socket, :members, members)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to update role.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Only the workspace owner can change roles.")}
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
              active={:workspace_members}
              workspace={@workspace}
              membership={@membership}
            />

            <PingbaseWeb.SettingsComponents.settings_panel>
              <h1 class="text-2xl font-bold text-base-content mb-6">Members</h1>

              <%= if @membership.role in ["owner", "admin"] do %>
                <PingbaseWeb.SettingsComponents.settings_section
                  title="Invite Members"
                  description="Send invites by email to join this workspace."
                >
                  <form phx-submit="send_invite" class="flex gap-3">
                    <input
                      type="email"
                      name="invite[email]"
                      value={@invite_email}
                      placeholder="colleague@company.com"
                      class="input input-bordered flex-1"
                      required
                    />
                    <button type="submit" class="btn btn-primary">Send Invite</button>
                  </form>
                </PingbaseWeb.SettingsComponents.settings_section>
              <% end %>

              <%= if @invites != [] do %>
                <PingbaseWeb.SettingsComponents.settings_section
                  title="Pending Invites"
                  description="Invites that haven't been accepted yet."
                >
                  <div class="divide-y divide-base-200">
                    <%= for invite <- @invites do %>
                      <div class="flex items-center justify-between py-3">
                        <div>
                          <div class="font-medium text-sm"><%= invite.email %></div>
                          <div class="text-xs text-base-content/60">
                            Invited by <%= invite.invited_by_user.name %>
                            · Expires <%= Calendar.strftime(invite.expires_at, "%b %d") %>
                          </div>
                        </div>
                        <%= if @membership.role in ["owner", "admin"] do %>
                          <button
                            phx-click="cancel_invite"
                            phx-value-id={invite.id}
                            class="btn btn-ghost btn-sm text-error"
                          >
                            Cancel
                          </button>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </PingbaseWeb.SettingsComponents.settings_section>
              <% end %>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Workspace Members"
                description="People who have access to this workspace."
              >
                <div class="divide-y divide-base-200">
                  <%= for member <- @members do %>
                    <div class="flex items-center justify-between py-3">
                      <div class="flex items-center gap-3">
                        <div class="w-8 h-8 rounded-full bg-primary text-primary-content flex items-center justify-center text-sm font-medium">
                          <%= String.first(member.user.name || "?") %>
                        </div>
                        <div>
                          <div class="font-medium text-sm"><%= member.user.name %></div>
                          <div class="text-xs text-base-content/60"><%= member.user.email %></div>
                        </div>
                      </div>
                      <div class="flex items-center gap-2">
                        <%= if @membership.role == "owner" && member.user.id != @current_user.id do %>
                          <form phx-submit="update_role" class="flex items-center gap-2">
                            <input type="hidden" name="user_id" value={member.user.id} />
                            <select name="role" class="select select-bordered select-sm">
                              <option value="admin" selected={member.role == "admin"}>Admin</option>
                              <option value="member" selected={member.role == "member"}>Member</option>
                            </select>
                            <button type="submit" class="btn btn-ghost btn-sm">Update</button>
                          </form>
                        <% else %>
                          <span class={"badge badge-sm #{role_badge_class(member.role)}"}>
                            <%= member.role %>
                          </span>
                        <% end %>
                        <%= if @membership.role in ["owner", "admin"] && member.user.id != @current_user.id do %>
                          <button
                            phx-click="remove_member"
                            phx-value-user-id={member.user.id}
                            data-confirm={"Are you sure you want to remove #{member.user.name} from this workspace?"}
                            class="btn btn-ghost btn-sm text-error"
                          >
                            Remove
                          </button>
                        <% end %>
                      </div>
                    </div>
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

  defp role_badge_class("owner"), do: "badge-primary"
  defp role_badge_class("admin"), do: "badge-secondary"
  defp role_badge_class(_), do: "badge-ghost"
end

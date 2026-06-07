defmodule PingbaseWeb.WorkspaceSettingsLive.General do
  @moduledoc """
  LiveView for editing workspace general settings.
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
        rooms = Chat.list_rooms(workspace)

        if membership == nil do
          {:ok, socket |> redirect(to: ~p"/")}
        else
          {:ok,
           socket
           |> assign(:workspace, workspace)
           |> assign(:membership, membership)
           |> assign(:rooms, rooms)
           |> assign(:page_title, "General Settings · #{workspace.name}")
           |> assign(:form, to_form(Workspaces.change_workspace(workspace)))}
        end
    end
  end

  @impl true
  def handle_event("save", %{"workspace" => workspace_params}, socket) do
    workspace = socket.assigns.workspace
    membership = socket.assigns.membership

    if membership.role in ["owner", "admin"] do
      case Workspaces.update_workspace(workspace, workspace_params) do
        {:ok, workspace} ->
          {:noreply,
           socket
           |> assign(:workspace, workspace)
           |> assign(:form, to_form(Workspaces.change_workspace(workspace)))
           |> put_flash(:info, "Workspace updated successfully.")}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to update this workspace.")}
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
              active={:workspace_general}
              workspace={@workspace}
              membership={@membership}
            />

            <PingbaseWeb.SettingsComponents.settings_panel>
              <h1 class="text-2xl font-bold text-base-content mb-6">General</h1>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Workspace Details"
                description="Basic information about your workspace."
              >
                <form phx-submit="save">
                  <PingbaseWeb.SettingsComponents.settings_form_group label="Workspace Name">
                    <input
                      type="text"
                      name="workspace[name]"
                      value={@form[:name].value}
                      class="input input-bordered w-full"
                      required
                      disabled={@membership.role not in ["owner", "admin"]}
                    />
                  </PingbaseWeb.SettingsComponents.settings_form_group>

                  <PingbaseWeb.SettingsComponents.settings_form_group label="Slug" hint="Used in URLs">
                    <input
                      type="text"
                      name="workspace[slug]"
                      value={@form[:slug].value}
                      class="input input-bordered w-full"
                      pattern="[a-z0-9-]+"
                      required
                      disabled={@membership.role not in ["owner", "admin"]}
                    />
                  </PingbaseWeb.SettingsComponents.settings_form_group>

                  <PingbaseWeb.SettingsComponents.settings_form_group label="Description">
                    <textarea
                      name="workspace[description]"
                      class="textarea textarea-bordered w-full"
                      rows="3"
                      disabled={@membership.role not in ["owner", "admin"]}
                    ><%= @form[:description].value %></textarea>
                  </PingbaseWeb.SettingsComponents.settings_form_group>

                  <%= if @membership.role in ["owner", "admin"] do %>
                    <div class="flex items-center gap-3 pt-2">
                      <button type="submit" class="btn btn-primary">Save Changes</button>
                    </div>
                  <% end %>
                </form>
              </PingbaseWeb.SettingsComponents.settings_section>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Workspace URL"
                description="Share this link with your team."
              >
                <div class="flex items-center gap-2 p-3 bg-base-200 rounded-lg">
                  <code class="text-sm flex-1 break-all"><%= PingbaseWeb.Endpoint.url() <> ~p"/w/#{@workspace.slug}" %></code>
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

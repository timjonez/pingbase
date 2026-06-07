defmodule PingbaseWeb.SettingsLive.Profile do
  @moduledoc """
  LiveView for editing the current user's profile.
  """
  use PingbaseWeb, :live_view

  alias Pingbase.Accounts
  alias Pingbase.Workspaces

  on_mount {PingbaseWeb.UserAuth, :require_user}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    workspaces = Workspaces.list_user_workspaces(user)

    {:ok,
     socket
     |> assign(:page_title, "Profile Settings")
     |> assign(:workspaces, workspaces)
     |> assign(:form, to_form(Accounts.change_user(user)))
     |> assign(:saved, false)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(:form, to_form(Accounts.change_user(user)))
         |> assign(:saved, true)
         |> put_flash(:info, "Profile updated successfully.")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> assign(:saved, false)}
    end
  end

  @impl true
  def handle_event("reset_saved", _params, socket) do
    {:noreply, assign(socket, :saved, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <div class="max-w-5xl mx-auto p-4 md:p-8">
        <div class="flex flex-col md:flex-row gap-8">
          <PingbaseWeb.SettingsComponents.settings_nav
            active={:profile}
            workspace={List.first(@workspaces)}
            membership={if List.first(@workspaces), do: Pingbase.Workspaces.get_membership(@current_user, List.first(@workspaces)), else: nil}
          />

          <PingbaseWeb.SettingsComponents.settings_panel>
            <h1 class="text-2xl font-bold text-base-content mb-6">Profile</h1>

            <PingbaseWeb.SettingsComponents.settings_section
              title="Public Profile"
              description="This information will be visible to everyone in your workspaces."
            >
              <form phx-submit="save" phx-change="reset_saved">
                <PingbaseWeb.SettingsComponents.settings_form_group label="Full Name">
                  <input
                    type="text"
                    name="user[name]"
                    value={@form[:name].value}
                    class="input input-bordered w-full"
                    placeholder="Your full name"
                  />
                </PingbaseWeb.SettingsComponents.settings_form_group>

                <PingbaseWeb.SettingsComponents.settings_form_group label="Display Name" hint="How you appear in chat">
                  <input
                    type="text"
                    name="user[display_name]"
                    value={@form[:display_name].value}
                    class="input input-bordered w-full"
                    placeholder="e.g. Alex"
                  />
                </PingbaseWeb.SettingsComponents.settings_form_group>

                <PingbaseWeb.SettingsComponents.settings_form_group label="Status Emoji">
                  <input
                    type="text"
                    name="user[status_emoji]"
                    value={@form[:status_emoji].value}
                    class="input input-bordered w-full"
                    placeholder="e.g. 🏖️"
                  />
                </PingbaseWeb.SettingsComponents.settings_form_group>

                <PingbaseWeb.SettingsComponents.settings_form_group label="Status Text">
                  <input
                    type="text"
                    name="user[status_text]"
                    value={@form[:status_text].value}
                    class="input input-bordered w-full"
                    placeholder="What's happening?"
                  />
                </PingbaseWeb.SettingsComponents.settings_form_group>

                <PingbaseWeb.SettingsComponents.settings_form_group label="Timezone">
                  <input
                    type="text"
                    name="user[timezone]"
                    value={@form[:timezone].value}
                    class="input input-bordered w-full"
                    placeholder="UTC"
                  />
                </PingbaseWeb.SettingsComponents.settings_form_group>

                <div class="flex items-center gap-3 pt-2">
                  <button type="submit" class="btn btn-primary">Save Changes</button>
                  <%= if @saved do %>
                    <span class="text-sm text-success">Saved!</span>
                  <% end %>
                </div>
              </form>
            </PingbaseWeb.SettingsComponents.settings_section>

            <PingbaseWeb.SettingsComponents.settings_section
              title="Avatar"
              description="Update your profile picture."
            >
              <div class="flex items-center gap-4">
                <div class="w-16 h-16 rounded-full bg-primary text-primary-content flex items-center justify-center text-2xl font-bold">
                  <%= String.first(@current_user.name || "?") %>
                </div>
                <div>
                  <p class="text-sm text-base-content/60">
                    Avatar upload coming soon. For now, update your avatar_url directly via the API.
                  </p>
                </div>
              </div>
            </PingbaseWeb.SettingsComponents.settings_section>
          </PingbaseWeb.SettingsComponents.settings_panel>
        </div>
      </div>
    </div>
    """
  end
end

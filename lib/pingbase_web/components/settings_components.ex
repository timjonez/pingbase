defmodule PingbaseWeb.SettingsComponents do
  @moduledoc """
  Shared components for settings pages.
  """
  use PingbaseWeb, :html

  def settings_nav(assigns) do
    ~H"""
    <nav class="w-full md:w-64 flex-shrink-0">
      <div class="space-y-6">
        <div>
          <h3 class="text-xs font-semibold text-base-content/60 uppercase tracking-wider mb-2 px-3">
            User Settings
          </h3>
          <div class="space-y-1">
            <.nav_item
              label="Profile"
              href={~p"/settings/profile"}
              active={@active == :profile}
            />
            <.nav_item
              label="API Tokens"
              href={~p"/settings/tokens"}
              active={@active == :tokens}
            />
          </div>
        </div>

        <%= if @workspace do %>
          <div>
            <h3 class="text-xs font-semibold text-base-content/60 uppercase tracking-wider mb-2 px-3">
              Workspace Settings
            </h3>
            <div class="space-y-1">
              <.nav_item
                label="General"
                href={~p"/w/#{@workspace.slug}/settings/general"}
                active={@active == :workspace_general}
              />
              <.nav_item
                label="Members"
                href={~p"/w/#{@workspace.slug}/settings/members"}
                active={@active == :workspace_members}
              />
              <.nav_item
                label="Notifications"
                href={~p"/w/#{@workspace.slug}/settings/notifications"}
                active={@active == :workspace_notifications}
              />
              <%= if @membership && @membership.role in ["owner", "admin"] do %>
                <.nav_item
                  label="Billing"
                  href={~p"/w/#{@workspace.slug}/settings/billing"}
                  active={@active == :workspace_billing}
                />
                <.nav_item
                  label="Integrations"
                  href={~p"/w/#{@workspace.slug}/settings/integrations"}
                  active={@active == :workspace_integrations}
                />
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </nav>
    """
  end

  def nav_item(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-colors",
        if(@active, do: "bg-primary/10 text-primary", else: "text-base-content/70 hover:bg-base-200 hover:text-base-content")
      ]}
    >
      <%= @label %>
    </.link>
    """
  end

  def settings_panel(assigns) do
    ~H"""
    <div class="flex-1 min-w-0">
      <div class="max-w-2xl">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def settings_section(assigns) do
    ~H"""
    <div class="bg-base-100 border border-base-300 rounded-xl p-6 mb-6">
      <%= if assigns[:title] do %>
        <h2 class="text-lg font-semibold text-base-content mb-1"><%= @title %></h2>
      <% end %>
      <%= if assigns[:description] do %>
        <p class="text-sm text-base-content/60 mb-4"><%= @description %></p>
      <% end %>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def settings_form_group(assigns) do
    ~H"""
    <div class="form-control mb-4">
      <%= if assigns[:label] do %>
        <label class="label">
          <span class="label-text font-medium"><%= @label %></span>
          <%= if assigns[:hint] do %>
            <span class="label-text-alt"><%= @hint %></span>
          <% end %>
        </label>
      <% end %>
      <%= render_slot(@inner_block) %>
      <%= if assigns[:error] do %>
        <label class="label">
          <span class="label-text-alt text-error"><%= @error %></span>
        </label>
      <% end %>
    </div>
    """
  end

  def workspace_sidebar(assigns) do
    ~H"""
    <div class="w-64 bg-base-200 border-r border-base-300 flex flex-col flex-shrink-0 hidden md:flex">
      <div class="p-4 border-b border-base-300">
        <h1 class="font-bold text-lg truncate"><%= @workspace.name %></h1>
      </div>
      <div class="flex-1 overflow-y-auto p-2 space-y-1">
        <div class="px-2 py-1 text-xs font-semibold text-base-content/60 uppercase tracking-wider">Channels</div>
        <%= for room <- @rooms do %>
          <%= if not room.is_archived do %>
            <.link
              navigate={~p"/w/#{@workspace.slug}/rooms/#{room.id}"}
              class="flex items-center justify-between px-2 py-1.5 rounded-lg text-sm transition-colors hover:bg-base-300"
            >
              <div class="flex items-center min-w-0">
                <span class="text-base-content/60 mr-2"><%= if room.type == "channel", do: "#", else: "@" %></span>
                <span class="truncate"><%= room.name %></span>
              </div>
            </.link>
          <% end %>
        <% end %>
      </div>
      <div class="p-3 border-t border-base-300">
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-full bg-primary text-primary-content flex items-center justify-center text-sm font-medium">
            <%= if @current_user, do: String.first(@current_user.name || "?"), else: "?" %>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm font-medium truncate"><%= if @current_user, do: @current_user.name, else: "Guest" %></div>
            <div class="text-xs text-base-content/60">Online</div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

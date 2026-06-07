defmodule PingbaseWeb.SettingsLive.Tokens do
  @moduledoc """
  LiveView for managing API tokens.
  """
  use PingbaseWeb, :live_view

  alias Pingbase.Accounts
  alias Pingbase.Workspaces

  on_mount {PingbaseWeb.UserAuth, :require_user}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    tokens = Accounts.list_user_api_tokens(user)
    workspaces = Workspaces.list_user_workspaces(user)

    {:ok,
     socket
     |> assign(:page_title, "API Tokens")
     |> assign(:workspaces, workspaces)
     |> assign(:tokens, tokens)
     |> assign(:new_token, nil)
     |> assign(:token_name, "")}
  end

  @impl true
  def handle_event("create", %{"token" => %{"name" => name}}, socket) do
    user = socket.assigns.current_user

    case Accounts.create_api_token(user, name) do
      {:ok, _api_token, token} ->
        tokens = Accounts.list_user_api_tokens(user)

        {:noreply,
         socket
         |> assign(:tokens, tokens)
         |> assign(:new_token, token)
         |> assign(:token_name, "")
         |> put_flash(:info, "API token created successfully. Copy it now — you won't see it again.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create token.")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    token = Enum.find(socket.assigns.tokens, &(&1.id == String.to_integer(id)))

    if token do
      Accounts.delete_api_token(token)
      tokens = Accounts.list_user_api_tokens(user)
      {:noreply, assign(socket, :tokens, tokens)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("dismiss_new", _params, socket) do
    {:noreply, assign(socket, :new_token, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <div class="max-w-5xl mx-auto p-4 md:p-8">
        <div class="flex flex-col md:flex-row gap-8">
          <PingbaseWeb.SettingsComponents.settings_nav
            active={:tokens}
            workspace={List.first(@workspaces)}
            membership={if List.first(@workspaces), do: Pingbase.Workspaces.get_membership(@current_user, List.first(@workspaces)), else: nil}
          />

          <PingbaseWeb.SettingsComponents.settings_panel>
            <h1 class="text-2xl font-bold text-base-content mb-6">API Tokens</h1>

            <PingbaseWeb.SettingsComponents.settings_section
              title="Create Token"
              description="Generate a new token to authenticate API requests."
            >
              <form phx-submit="create" class="flex gap-3">
                <input
                  type="text"
                  name="token[name]"
                  value={@token_name}
                  placeholder="Token name (e.g. CLI, CI/CD)"
                  class="input input-bordered flex-1"
                  required
                />
                <button type="submit" class="btn btn-primary">Create Token</button>
              </form>

              <%= if @new_token do %>
                <div class="mt-4 p-4 bg-warning/10 border border-warning/20 rounded-lg">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-sm font-medium text-warning">New Token — Copy it now!</span>
                    <button phx-click="dismiss_new" class="text-sm text-base-content/60 hover:text-base-content">Dismiss</button>
                  </div>
                  <code class="block p-3 bg-base-200 rounded text-sm font-mono break-all"><%= @new_token %></code>
                </div>
              <% end %>
            </PingbaseWeb.SettingsComponents.settings_section>

            <PingbaseWeb.SettingsComponents.settings_section
              title="Your Tokens"
              description="Active tokens that can access the API on your behalf."
            >
              <%= if @tokens == [] do %>
                <p class="text-sm text-base-content/60">You don't have any API tokens yet.</p>
              <% else %>
                <div class="divide-y divide-base-200">
                  <%= for token <- @tokens do %>
                    <div class="flex items-center justify-between py-3">
                      <div>
                        <div class="font-medium text-sm"><%= token.name %></div>
                        <div class="text-xs text-base-content/60">
                          Created <%= Calendar.strftime(token.inserted_at, "%b %d, %Y") %>
                          <%= if token.last_used_at do %>
                            · Last used <%= Calendar.strftime(token.last_used_at, "%b %d, %Y") %>
                          <% else %>
                            · Never used
                          <% end %>
                        </div>
                      </div>
                      <button
                        phx-click="delete"
                        phx-value-id={token.id}
                        data-confirm="Are you sure you want to revoke this token?"
                        class="btn btn-ghost btn-sm text-error"
                      >
                        Revoke
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </PingbaseWeb.SettingsComponents.settings_section>
          </PingbaseWeb.SettingsComponents.settings_panel>
        </div>
      </div>
    </div>
    """
  end
end

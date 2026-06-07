defmodule PingbaseWeb.WorkspaceSettingsLive.Billing do
  @moduledoc """
  LiveView for workspace billing settings (admin only).
  """
  use PingbaseWeb, :live_view

  alias Pingbase.Workspaces
  alias Pingbase.Billing
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
          invoices = Billing.list_workspace_invoices(workspace)
          billing_events = Billing.list_workspace_billing_events(workspace)
          seat_limit = Billing.seat_limit_for_plan(workspace.plan)

          {:ok,
           socket
           |> assign(:workspace, workspace)
           |> assign(:membership, membership)
           |> assign(:rooms, rooms)
           |> assign(:invoices, invoices)
           |> assign(:billing_events, billing_events)
           |> assign(:seat_limit, seat_limit)
           |> assign(:page_title, "Billing · #{workspace.name}")}
        end
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
              active={:workspace_billing}
              workspace={@workspace}
              membership={@membership}
            />

            <PingbaseWeb.SettingsComponents.settings_panel>
              <h1 class="text-2xl font-bold text-base-content mb-6">Billing</h1>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Current Plan"
                description="Your workspace's current subscription plan."
              >
                <div class="flex items-center justify-between p-4 bg-base-200 rounded-lg">
                  <div>
                    <div class="font-semibold text-base-content capitalize"><%= @workspace.plan %></div>
                    <div class="text-sm text-base-content/60">
                      <%= if @workspace.plan == "free" do %>
                        Up to <%= Billing.free_seats() %> users
                      <% else %>
                        Unlimited users
                      <% end %>
                    </div>
                  </div>
                  <span class={"badge badge-lg #{plan_badge_class(@workspace.plan)}"}>
                    <%= @workspace.plan %>
                  </span>
                </div>

                <div class="mt-4">
                  <div class="flex items-center justify-between text-sm mb-1">
                    <span>Seat usage</span>
                    <span class="font-medium"><%= @workspace.seats_count %> / <%= if @seat_limit, do: @seat_limit, else: "∞" %></span>
                  </div>
                  <%= if @seat_limit do %>
                    <progress
                      class="progress progress-primary w-full"
                      value={@workspace.seats_count}
                      max={@seat_limit}
                    ></progress>
                  <% else %>
                    <progress class="progress progress-primary w-full" value={0} max={1}></progress>
                  <% end %>
                </div>
              </PingbaseWeb.SettingsComponents.settings_section>

              <%= if @invoices != [] do %>
                <PingbaseWeb.SettingsComponents.settings_section
                  title="Invoices"
                  description="Billing history for this workspace."
                >
                  <div class="divide-y divide-base-200">
                    <%= for invoice <- @invoices do %>
                      <div class="flex items-center justify-between py-3">
                        <div>
                          <div class="font-medium text-sm"><%= invoice.number %></div>
                          <div class="text-xs text-base-content/60">
                            <%= Calendar.strftime(invoice.inserted_at, "%b %d, %Y") %>
                          </div>
                        </div>
                        <div class="flex items-center gap-3">
                          <span class="text-sm font-medium">$<%= invoice.amount %></span>
                          <span class={"badge badge-sm #{if invoice.status == "paid", do: "badge-success", else: "badge-warning"}"}>
                            <%= invoice.status %>
                          </span>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </PingbaseWeb.SettingsComponents.settings_section>
              <% end %>

              <%= if @billing_events != [] do %>
                <PingbaseWeb.SettingsComponents.settings_section
                  title="Billing Events"
                  description="Recent billing activity."
                >
                  <div class="divide-y divide-base-200">
                    <%= for event <- @billing_events do %>
                      <div class="flex items-center justify-between py-3">
                        <div>
                          <div class="font-medium text-sm capitalize"><%= String.replace(event.event_type, "_", " ") %></div>
                          <div class="text-xs text-base-content/60">
                            <%= Calendar.strftime(event.inserted_at, "%b %d, %Y %H:%M") %>
                          </div>
                        </div>
                        <%= if event.amount do %>
                          <span class="text-sm font-medium">$<%= event.amount %></span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </PingbaseWeb.SettingsComponents.settings_section>
              <% end %>

              <PingbaseWeb.SettingsComponents.settings_section
                title="Self-Hosted Notice"
                description="Billing is only relevant for SaaS deployments."
              >
                <p class="text-sm text-base-content/60">
                  If you're self-hosting Pingbase, all features are free and unlimited.
                  Billing controls are shown here for workspaces managed through the SaaS offering.
                </p>
              </PingbaseWeb.SettingsComponents.settings_section>
            </PingbaseWeb.SettingsComponents.settings_panel>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp plan_badge_class("free"), do: "badge-ghost"
  defp plan_badge_class("team"), do: "badge-primary"
  defp plan_badge_class("enterprise"), do: "badge-secondary"
  defp plan_badge_class(_), do: "badge-ghost"
end

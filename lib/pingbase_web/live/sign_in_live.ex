defmodule PingbaseWeb.SignInLive do
  @moduledoc """
  LiveView for the sign-in page. Users enter their email to receive a magic link.
  """
  use PingbaseWeb, :live_view

  on_mount {PingbaseWeb.UserAuth, :require_guest}

  alias Pingbase.Accounts
  alias Pingbase.Accounts.UserNotifier
  alias Pingbase.Accounts.MagicLink

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign in")
     |> assign(:email, "")
     |> assign(:sending, false)
     |> assign(:sent, false)}
  end

  @impl true
  def handle_event("send_magic_link", %{"user" => %{"email" => email}}, socket) do
    socket = assign(socket, :sending, true)

    case Accounts.get_user_by_email(email) do
      nil ->
        # Don't reveal whether the email exists
        {:noreply,
         socket
         |> assign(:sending, false)
         |> assign(:sent, true)
         |> put_flash(:info, "If this email exists, a magic link has been sent.")}

      user ->
        {token, hashed} = MagicLink.generate_token()
        MagicLink.store_token(user, hashed)

        link = PingbaseWeb.Endpoint.url() <> "/sign-in/verify?token=#{token}"
        UserNotifier.deliver_magic_link(user, link)

        {:noreply,
         socket
         |> assign(:sending, false)
         |> assign(:sent, true)
         |> put_flash(:info, "If this email exists, a magic link has been sent.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 flex items-center justify-center p-4">
      <div class="w-full max-w-md space-y-6">
        <div class="text-center">
          <div class="w-16 h-16 rounded-2xl bg-primary text-primary-content flex items-center justify-center mx-auto text-3xl font-bold mb-4">
            P
          </div>
          <h1 class="text-2xl font-bold text-base-content">Sign in to Pingbase</h1>
          <p class="text-base-content/60 mt-2">We'll send you a magic link to sign in instantly.</p>
        </div>

        <%= if @sent do %>
          <div class="alert alert-success">
            <span>Check your email for the magic link!</span>
          </div>
        <% else %>
          <form phx-submit="send_magic_link" class="space-y-4">
            <div class="form-control">
              <label class="label">
                <span class="label-text">Email</span>
              </label>
              <input
                type="email"
                name="user[email]"
                placeholder="you@company.com"
                class="input input-bordered w-full"
                required
              />
            </div>

            <button type="submit" class="btn btn-primary w-full" disabled={@sending}>
              <%= if @sending, do: "Sending...", else: "Send Magic Link" %>
            </button>
          </form>
        <% end %>

        <div class="text-center">
          <a href="/" class="btn btn-ghost btn-sm">← Back to home</a>
        </div>
      </div>
    </div>
    """
  end
end

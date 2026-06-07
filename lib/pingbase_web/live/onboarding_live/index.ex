defmodule PingbaseWeb.OnboardingLive.Index do
  @moduledoc """
  Multi-step onboarding flow:

  1. welcome   — Welcome screen
  2. auth      — Email input for magic link
  3. verify    — Token verification (handled via /verify/:token)
  4. workspace — Create first workspace
  5. invite    — Invite team members (optional)
  6. done      — Redirect to workspace
  """
  use PingbaseWeb, :live_view

  alias Pingbase.Accounts
  alias Pingbase.Accounts.UserNotifier
  alias Pingbase.Workspaces
  alias Pingbase.Chat
  alias Pingbase.Accounts.MagicLink

  @impl true
  def mount(params, session, socket) do
    step = parse_step(params["step"])
    user = get_user_from_session(session)

    socket =
      socket
      |> assign(:step, step)
      |> assign(:user, user)
      |> assign(:page_title, "Welcome to Pingbase")
      |> assign(:email, "")
      |> assign(:workspace_name, "")
      |> assign(:workspace_slug, "")
      |> assign(:invite_emails, "")
      |> assign(:sending, false)
      |> assign(:errors, %{})
      |> assign(:invite_token, params["invite"])

    {:ok, socket}
  end

  defp parse_step(nil), do: :welcome
  defp parse_step("welcome"), do: :welcome
  defp parse_step("auth"), do: :auth
  defp parse_step("workspace"), do: :workspace
  defp parse_step("invite"), do: :invite
  defp parse_step("done"), do: :done
  defp parse_step(_), do: :welcome

  defp get_user_from_session(session) do
    case session do
      %{"user_id" => user_id} -> Accounts.get_user!(user_id)
      _ -> nil
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    step = parse_step(params["step"])
    {:noreply, assign(socket, :step, step)}
  end

  @impl true
  def handle_event("next", %{"step" => step}, socket) do
    {:noreply, push_patch(socket, to: "/onboarding/#{step}")}
  end

  @impl true
  def handle_event("send_magic_link", %{"user" => %{"email" => email}}, socket) do
    socket = assign(socket, :sending, true)

    case Accounts.get_user_by_email(email) do
      nil ->
        {:ok, user} = Accounts.create_user(%{email: email, name: email |> String.split("@") |> hd()})
        send_magic_link(user, socket)

      user ->
        send_magic_link(user, socket)
    end
  end

  @impl true
  def handle_event("create_workspace", %{"workspace" => %{"name" => name, "slug" => slug}}, socket) do
    user = socket.assigns.user

    if is_nil(user) do
      {:noreply, socket |> put_flash(:error, "Please sign in first.") |> push_patch(to: "/onboarding/auth")}
    else
      attrs = %{name: name, slug: slug}

      case Workspaces.create_workspace(user, attrs) do
        {:ok, workspace} ->
          # Create default #general channel
          {:ok, room} =
            Chat.create_room(%{
              workspace_id: workspace.id,
              name: "general",
              slug: "general",
              type: "channel",
              topic: "General discussion"
            })

          {:noreply,
           socket
           |> assign(:workspace, workspace)
           |> assign(:room, room)
           |> push_patch(to: "/onboarding/invite")}

        {:error, changeset} ->
          errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Regex.replace(~r/%{(.+)}/, msg, fn _, key ->
              opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
            end)
          end)

          {:noreply, assign(socket, :errors, errors)}
      end
    end
  end

  @impl true
  def handle_event("skip_invite", _params, socket) do
    workspace = socket.assigns.workspace
    room = socket.assigns.room

    {:noreply,
     socket
     |> push_navigate(to: "/w/#{workspace.slug}/rooms/#{room.id}")}
  end

  @impl true
  def handle_event("send_invites", %{"invites" => %{"emails" => emails}}, socket) do
    user = socket.assigns.user
    workspace = socket.assigns.workspace

    emails
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.each(fn email ->
      Workspaces.create_invite(workspace, user, email)
    end)

    {:noreply,
     socket
     |> push_navigate(to: "/w/#{workspace.slug}/rooms/#{socket.assigns.room.id}")}
  end

  defp send_magic_link(user, socket) do
    {token, hashed} = MagicLink.generate_token()
    MagicLink.store_token(user, hashed)

    invite_param =
      if socket.assigns.invite_token do
        "&invite=#{socket.assigns.invite_token}"
      else
        ""
      end

    link =
      PingbaseWeb.Endpoint.url() <> "/onboarding/verify?token=#{token}" <> invite_param

    UserNotifier.deliver_magic_link(user, link)

    {:noreply,
     socket
     |> assign(:sending, false)
     |> put_flash(:info, "Magic link sent! Check your email.")
     |> push_patch(to: "/onboarding/auth")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 flex items-center justify-center p-4">
      <div class="w-full max-w-md">
        <%= case @step do %>
          <% :welcome -> %>
            <.welcome_step />
          <% :auth -> %>
            <.auth_step sending={@sending} />
          <% :workspace -> %>
            <.workspace_step user={@user} errors={@errors} />
          <% :invite -> %>
            <.invite_step workspace={@workspace} />
          <% :done -> %>
            <.done_step />
        <% end %>
      </div>
    </div>
    """
  end

  def welcome_step(assigns) do
    ~H"""
    <div class="text-center space-y-6">
      <div class="w-16 h-16 rounded-2xl bg-primary text-primary-content flex items-center justify-center mx-auto text-3xl font-bold">
        P
      </div>
      <h1 class="text-3xl font-bold text-base-content">Welcome to Pingbase</h1>
      <p class="text-base-content/60 text-lg">
        The calm alternative to Slack. Built for teams that value focus over chaos.
      </p>
      <div class="space-y-3 pt-4">
        <button
          phx-click="next"
          phx-value-step="auth"
          class="btn btn-primary w-full"
        >
          Get Started
        </button>
        <p class="text-sm text-base-content/60">
          Already have an account? <a href="/sign-in" class="link link-primary">Sign in</a>
        </p>
      </div>
    </div>
    """
  end

  def auth_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="text-center">
        <h2 class="text-2xl font-bold text-base-content">Sign in with email</h2>
        <p class="text-base-content/60 mt-2">We'll send you a magic link to sign in instantly.</p>
      </div>

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

      <div class="text-center">
        <button
          phx-click="next"
          phx-value-step="welcome"
          class="btn btn-ghost btn-sm"
        >
          ← Back
        </button>
      </div>
    </div>
    """
  end

  def workspace_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="text-center">
        <h2 class="text-2xl font-bold text-base-content">Create your workspace</h2>
        <p class="text-base-content/60 mt-2">This is where your team will chat.</p>
      </div>

      <form phx-submit="create_workspace" class="space-y-4">
        <div class="form-control">
          <label class="label">
            <span class="label-text">Workspace name</span>
          </label>
          <input
            type="text"
            name="workspace[name]"
            placeholder="Acme Inc"
            class="input input-bordered w-full"
            required
          />
          <%= if @errors[:name] do %>
            <label class="label">
              <span class="label-text-alt text-error"><%= hd(@errors[:name]) %></span>
            </label>
          <% end %>
        </div>

        <div class="form-control">
          <label class="label">
            <span class="label-text">Workspace URL</span>
            <span class="label-text-alt">Lowercase, no spaces</span>
          </label>
          <div class="flex items-center gap-2">
            <span class="text-sm text-base-content/60">pingbase.com/w/</span>
            <input
              type="text"
              name="workspace[slug]"
              placeholder="acme"
              class="input input-bordered w-full"
              pattern="[a-z0-9-]+"
              required
            />
          </div>
          <%= if @errors[:slug] do %>
            <label class="label">
              <span class="label-text-alt text-error"><%= hd(@errors[:slug]) %></span>
            </label>
          <% end %>
        </div>

        <button type="submit" class="btn btn-primary w-full">
          Create Workspace
        </button>
      </form>
    </div>
    """
  end

  def invite_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="text-center">
        <h2 class="text-2xl font-bold text-base-content">Invite your team</h2>
        <p class="text-base-content/60 mt-2">You can always invite people later.</p>
      </div>

      <form phx-submit="send_invites" class="space-y-4">
        <div class="form-control">
          <label class="label">
            <span class="label-text">Email addresses</span>
            <span class="label-text-alt">Separate with commas</span>
          </label>
          <textarea
            name="invites[emails]"
            placeholder="alice@company.com, bob@company.com"
            class="textarea textarea-bordered w-full"
            rows="3"
          ></textarea>
        </div>

        <div class="flex gap-3">
          <button type="button" phx-click="skip_invite" class="btn btn-ghost flex-1">
            Skip for now
          </button>
          <button type="submit" class="btn btn-primary flex-1">
            Send Invites
          </button>
        </div>
      </form>
    </div>
    """
  end

  def done_step(assigns) do
    ~H"""
    <div class="text-center space-y-6">
      <div class="w-16 h-16 rounded-full bg-success text-success-content flex items-center justify-center mx-auto text-3xl">
        ✓
      </div>
      <h2 class="text-2xl font-bold text-base-content">You're all set!</h2>
      <p class="text-base-content/60">Redirecting you to your workspace...</p>
    </div>
    """
  end
end

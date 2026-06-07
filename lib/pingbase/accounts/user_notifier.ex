defmodule Pingbase.Accounts.UserNotifier do
  @moduledoc """
  Handles sending emails to users.
  """

  import Swoosh.Email

  alias Pingbase.Mailer

  def deliver_magic_link(user, link) do
    email =
      new()
      |> to({user.name || user.email, user.email})
      |> from({"Pingbase", "no-reply@pingbase.com"})
      |> subject("Your magic sign-in link")
      |> text_body("""
      Hi there,

      Click the link below to sign in to Pingbase:

      #{link}

      This link will expire in 24 hours.

      If you didn't request this, you can safely ignore this email.
      """)

    Mailer.deliver(email)
  end

  def deliver_workspace_invite(email_address, workspace, invited_by, invite_link) do
    email =
      new()
      |> to(email_address)
      |> from({"Pingbase", "no-reply@pingbase.com"})
      |> subject("You've been invited to join #{workspace.name} on Pingbase")
      |> text_body("""
      Hi there,

      #{invited_by.name || invited_by.email} has invited you to join the workspace "#{workspace.name}" on Pingbase.

      Click the link below to accept the invite:

      #{invite_link}

      This invite will expire in 7 days.

      If you don't have a Pingbase account yet, you'll be able to create one when you accept the invite.
      """)

    Mailer.deliver(email)
  end
end

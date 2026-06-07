# Sign-In Feature Spec

## Overview
Provide a dedicated sign-in flow for returning users, separate from onboarding. Uses magic link (passwordless) authentication.

## Goals
- Allow returning users to sign in via email magic link
- Redirect existing users to their workspace after sign-in
- Provide sign-out functionality
- Link sign-in page from the home page and onboarding

## Non-Goals
- Password-based authentication (magic links only)
- Social login (OAuth)
- MFA / 2FA

## Flow

1. User clicks "Sign in" on the home page or onboarding
2. User enters their email on `/sign-in`
3. System sends a magic link to the email
4. User clicks the link → `/sign-in/verify?token=<token>`
5. System validates the token, sets the session cookie
6. If the user has workspaces → redirect to the first workspace
7. If the user has no workspaces → redirect to `/onboarding/workspace`

## UI
- `/sign-in` — Clean centered page with email input, same styling as onboarding auth step
- Home page — Add "Sign in" link alongside "Get Started"
- Onboarding auth step — Link to `/sign-in` instead of `/`
- Layout — When user is signed in, show sign-out in the header

## API / Backend
- Reuse `Accounts.MagicLink` for token generation and verification
- Reuse `Accounts.UserNotifier` for email delivery
- Add `Accounts.get_user_by_email/1` (already exists)
- Add `Accounts.get_user_workspaces/1` to determine redirect
- New controller: `SignInController` for verification (to set session and redirect)
- New LiveView: `SignInLive` for the email form
- Add sign-out route that clears session and redirects to `/`

## Redirect Logic
After successful magic link verification:
- Query user's workspaces via `Workspaces.list_user_workspaces(user)`
- If workspaces exist → redirect to `/w/<first-workspace-slug>`
- If no workspaces → redirect to `/onboarding/workspace`

## Security
- Magic links expire after 24 hours
- Token is cleared from the database after use
- Session cookie is HttpOnly, SameSite=Lax
- Sign-out clears the session

## Tests
- Sign-in page renders
- Submitting email sends magic link
- Valid token verifies and sets session
- Invalid token shows error
- Expired token shows error
- Existing user with workspaces redirects to workspace
- Existing user without workspaces redirects to onboarding workspace
- Sign-out clears session

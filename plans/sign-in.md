# Sign-In Implementation Plan

## Steps

### 1. Backend — Add `list_user_workspaces` to Workspaces context
- Add `Pingbase.Workspaces.list_user_workspaces/1` that returns workspaces a user is a member of
- Needed to determine redirect after sign-in

### 2. Web — Create `SignInLive` (LiveView)
- Route: `GET /sign-in`
- Renders email form, same styling as onboarding auth step
- On submit, generates magic link, sends email, shows flash

### 3. Web — Create `SignInController`
- Route: `GET /sign-in/verify?token=<token>`
- Verifies token via `MagicLink.verify_token/1`
- Sets session cookie
- Redirects based on workspace membership

### 4. Web — Update `PageController.home` page
- Add "Sign in" link on the home page
- Style consistently with existing design

### 5. Web — Update `OnboardingLive` auth step
- Change "Already have an account? Sign in" link to `/sign-in`

### 6. Web — Update `UserAuth`
- Add `on_mount(:require_guest)` to redirect already-signed-in users away from sign-in

### 7. Web — Add sign-out
- Route: `GET /sign-out` (or `DELETE /sign-out` via form/link)
- Controller action: clear session, redirect to `/`
- Update layout to show sign-out when signed in

### 8. Router — Register routes
- Add `/sign-in`, `/sign-in/verify`, `/sign-out`
- Apply appropriate pipelines

### 9. Tests
- `SignInLiveTest` — render, submit email
- `SignInControllerTest` — verify token, redirect logic
- Update `OnboardingLiveTest` if link changes
- Update `PageControllerTest` if home page changes

## Verification
- `mix test` passes
- Manual check: visit `/sign-in`, enter email, click link, verify redirect
- Docker logs show no errors

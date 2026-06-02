# Pingbase Implementation Plan

## Overview

Pingbase is an open-source, multi-tenant team chat application built with Elixir/Phoenix + LiveView. It serves as a calm, user-controlled alternative to Slack.

**Business Model:**
- Self-hosted: All features free, no restrictions (O'Saasy License)
- SaaS: Per-seat freemium (10 free users, then paid via Stripe)
- Creator runs the SaaS; license forbids competing SaaS offerings

**Philosophy:**
- Calm over chaos
- User controls notifications and presence
- Simple, tested core
- No AI bloat

---

## Architecture

### Stack
- **Language:** Elixir 1.17+
- **Framework:** Phoenix 1.8, Phoenix LiveView
- **CSS:** Tailwind CSS 4 + DaisyUI
- **Database:** PostgreSQL 16+
- **Background Jobs:** Oban
- **Auth:** Magic links (web) + API tokens (API/MCP/CLI)
- **Email:** Swoosh (configurable: Mailpit dev, SendGrid/Postmark/SMTP prod)
- **File Storage:** S3-compatible (MinIO dev, AWS/R2 prod)
- **Real-Time:** Phoenix PubSub + Presence
- **Billing:** Stripe (StripityStripe), webhooks
- **Testing:** ExUnit
- **Deployment:** Docker + Docker Compose

### Pattern: Service-Layer First

All business logic lives in contexts. LiveViews and API controllers are thin wrappers.

```
HTTP Request → Router → LiveView / API Controller → Context → DB
                                        ↑
                                    PubSub (real-time)
```

### Context Boundaries

| Context | Responsibility |
|---------|---------------|
| `Accounts` | Users, auth, sessions, API tokens, profiles |
| `Billing` | Stripe customers, subscriptions, invoices, plan enforcement |
| `Workspaces` | Workspace CRUD, memberships, invites, roles |
| `Chat` | Rooms, messages, reactions, threads, attachments, mentions |
| `Notifications` | Create notifications, mark read, unread counts, digests |
| `Integrations` | Incoming/outgoing webhooks, slash commands |
| `Uploads` | S3 presigned URLs, file metadata |

---

## Data Model

> All tables singular. Every table has `created_at` and `updated_at`.

### Accounts
```
user
  id, email, name, display_name, avatar_url, timezone, status_text, status_emoji

workspace
  id, slug, name, description, avatar_url, plan, billing_status, stripe_customer_id,
  stripe_subscription_id, seats_count, seats_limit, trial_ends_at

workspace_membership
  id, user_id, workspace_id, role (owner | admin | member), notification_pref

workspace_invite
  id, workspace_id, email, invited_by_user_id, accepted_at, expires_at

api_token
  id, user_id, name, token_hash, last_used_at
```

### Billing
```
billing_event
  id, workspace_id, event_type, amount, metadata

invoice
  id, workspace_id, stripe_invoice_id, amount_due, amount_paid, status, period_start, period_end
```

### Chat
```
room
  id, workspace_id, type (channel | dm | thread), name, slug, topic, is_archived

room_membership
  id, room_id, user_id, last_read_message_id, notification_level (all | mentions | none)

message
  id, room_id, user_id, parent_id, content, edited_at

message_reaction
  id, message_id, user_id, emoji

message_mention
  id, message_id, mentioned_user_id

attachment
  id, message_id, filename, url, size, mime_type
```

### Notifications
```
notification
  id, user_id, type (mention | invite | thread_reply | billing_alert), resource_type, resource_id, read_at
```

### Integrations
```
incoming_webhook
  id, workspace_id, name, token, room_id

outgoing_webhook
  id, workspace_id, name, url, events, active

slash_command
  id, workspace_id, command, description, url, token, room_id
```

---

## Authentication

| Client | Method |
|--------|--------|
| Web (LiveView) | Magic link email → session cookie |
| API / CLI / MCP | Bearer token (`Authorization: Token <token>`) |

Email providers configurable via environment:
- Dev: Mailpit (`localhost:8025`)
- Prod: SendGrid, Postmark, Amazon SES, or SMTP

---

## Billing

### Free Tier
- Up to 10 users per workspace
- All features included
- No credit card required

### Paid Tier
- 11+ users: per seat monthly
- Same features, no restrictions
- Stripe subscription with per-seat metering

### Plan Enforcement
```elixir
def add_member(workspace, user) do
  if workspace.seats_count >= workspace.seats_limit do
    {:error, :seat_limit_reached}
  else
    # create membership, increment seats_count
    # if now over 10, trigger Stripe invoice item
  end
end
```

### Self-Hosted vs SaaS
- Self-hosted: `plan` = `self_hosted`, `seats_limit` = `nil` (unlimited)
- SaaS: Stripe manages plan + seat count
- Billing checks skipped when `stripe_customer_id` is `nil`

---

## Real-Time Architecture

### PubSub Topics
- `"room:{room_id}"` — Messages, edits, reactions
- `"workspace:{workspace_id}:presence"` — Online users
- `"user:{user_id}:notifications"` — Personal notifications
- `"user:{user_id}:rooms"` — Room list changes
- `"workspace:{workspace_id}:billing"` — Billing events

### Presence
- Manual status only (no automatic green dots)
- Typing indicators: debounced, ephemeral, no DB writes

---

## Frontend: DaisyUI + Tailwind

### Design System
- DaisyUI semantic components
- Custom Pingbase brand colors
- Mobile-first responsive design

### Key UI Patterns
- **Zen mode**: Collapse sidebar, hide presence, full-width chat
- **Focus mode**: Top-bar toggle, suppresses non-urgent notifications
- **Sidebar**: Favorites + auto-collapsed sections (Active, Archived, DMs)
- **Thread pane**: Right sidebar (Slack/Teams-style), collapsible "Old" section
- **Notification badge**: Subtle, no aggressive red
- **File previews**: Inline images, PDFs/other files as download cards
- **Billing UI**: Seat usage bar, upgrade prompt when near limit

### Accessibility
- Keyboard navigation, ARIA labels, focus management
- Skeleton loading states, not spinners
- Color not the only information carrier

---

## Feature Roadmap

### Phase 1: Foundation + Auth + Billing Infrastructure

1. Initialize Phoenix project with Tailwind
2. Configure DaisyUI
3. Set up Docker + docker-compose
4. Create database migrations for Phase 1 tables:
   - users, workspaces, workspace_memberships, workspace_invites, api_tokens
   - billing_events, invoices
5. Implement Accounts context (users, magic link auth, API tokens)
6. Implement Billing context (Stripe customers, subscriptions, plan enforcement)
7. Implement Workspaces context (CRUD, memberships, invites)
8. Create app shell layout with DaisyUI sidebar

### Phase 2: Core Chat

1. Room contexts (channels, DMs)
2. Message context (CRUD, mentions parsing, notifications)
3. Reactions context
4. Attachments / uploads context (S3 presigned)
5. Thread sidebar
6. LiveView streams + infinite scroll
7. Typing indicators (Presence)
8. Room auto-archive → collapsed section
9. Notification contexts + badge

### Phase 3: Slack Compatibility

1. Incoming webhooks controller (Slack-compatible)
2. Slash commands controller
3. Outgoing webhooks context

### Phase 4: Search + Polish + API Prep

1. Search context (PostgreSQL tsvector)
2. Focus mode / DND
3. Per-room notification settings
4. Keyboard shortcuts
5. Admin settings
6. Billing dashboard
7. API controller stubs (JSON responses, token auth)
8. Final testing

### Phase 5: MCP Server (v2)

1. HTTP SSE endpoint
2. Tool definitions mapped to contexts
3. MCP configuration docs

### Phase 6: CLI (v2)

1. CLI tool (language TBD)
2. Auth via API token
3. Commands: send, read, search, status

---

## Engineering Standards

| Requirement | Compliance |
|-------------|-----------|
| `docs/`, `specs/`, `plans/` | Created before implementation |
| Tests for all features | ExUnit contexts, LiveView feature tests |
| Responsive mobile design | Mobile-first Tailwind + DaisyUI |
| Centered pages | Non-full-width pages centered |
| Reusable components | Extract LiveComponents after 2nd use or >200 lines |
| Singular table names | Enforced in all migrations |
| `created_at` + `updated_at` | Every table includes both |
| Frontend skill | DaisyUI-based, accessible, progressive disclosure |

---

## Stripe Dev Setup

```bash
# Install Stripe CLI
stripe login
stripe listen --forward-to localhost:4000/webhooks/stripe
```

---

## Notes

- MCP is a core selling point — contexts must be machine-friendly
- CLI should be able to do "just about anything" — another agent interface
- All context functions must remain pure and API-agnostic
- Self-hosters get all features; SaaS has seat limits only

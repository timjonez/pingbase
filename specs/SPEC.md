# Pingbase Feature Specification

## Overview

Multi-tenant team chat application with Slack-compatible webhooks, per-seat freemium SaaS billing, and a calm, anti-Slack UX.

## Architecture

- Thin LiveViews + rich service-layer contexts
- Phoenix PubSub for real-time messaging
- Presence for online status and typing indicators
- API tokens for MCP/CLI access

## Database Model

All tables singular, with `created_at` and `updated_at`.

### Accounts
- `user` — email, name, display_name, avatar_url, timezone, status_text, status_emoji
- `workspace` — slug, name, plan, billing_status, stripe_customer_id, seats_count, seats_limit
- `workspace_membership` — user_id, workspace_id, role, notification_pref
- `workspace_invite` — workspace_id, email, invited_by_user_id, accepted_at, expires_at
- `api_token` — user_id, name, token_hash, last_used_at

### Billing
- `billing_event` — workspace_id, event_type, amount, metadata
- `invoice` — workspace_id, stripe_invoice_id, amount_due, amount_paid, status

### Chat
- `room` — workspace_id, type (channel/dm/thread), name, slug, topic, is_archived
- `room_membership` — room_id, user_id, last_read_message_id, notification_level
- `message` — room_id, user_id, parent_id, content, edited_at
- `message_reaction` — message_id, user_id, emoji
- `message_mention` — message_id, mentioned_user_id
- `attachment` — message_id, filename, url, size, mime_type

### Notifications
- `notification` — user_id, type, resource_type, resource_id, read_at

### Integrations
- `incoming_webhook` — workspace_id, name, token, room_id
- `outgoing_webhook` — workspace_id, name, url, events, active
- `slash_command` — workspace_id, command, description, url, token, room_id

## Auth

- **Web**: Magic link email → session cookie
- **API/MCP/CLI**: Bearer token (`Authorization: Token <token>`)

## Billing

- Free tier: up to 10 users per workspace
- Paid: per seat, Stripe subscription
- Self-hosted: all features free, no restrictions

## Real-Time

- PubSub topics per room, workspace, user
- Presence for online status and typing
- No automatic green dots — manual status only

## Frontend

- DaisyUI + Tailwind CSS
- Mobile-first responsive
- Zen mode, focus mode, thread sidebar
- Auto-collapsed sidebar sections

## Slack Compatibility

- Slack-compatible incoming webhooks
- Slash commands
- Outgoing webhooks

## MCP (v2)

- HTTP SSE endpoint
- Tools: list_channels, send_message, get_thread, search_messages, etc.

## CLI (v2)

- Auth via API token
- Commands for send, read, search, status

# Phase 2: Core Chat — Implementation Plan

## Overview

Phase 1 established the foundation: users, auth, workspaces, billing stubs, and basic database schemas. Phase 2 wires up the actual chat experience: real-time messaging, threads, notifications, and responsive UI.

## Goals

1. **Real-time messaging** via PubSub — messages appear instantly for all room members
2. **Message creation with mention parsing** — `@user` creates notifications
3. **Thread sidebar** — right-pane thread view for replies
4. **LiveView streams + infinite scroll** — efficient message list rendering
5. **Typing indicators** — ephemeral presence-based typing
6. **Room auto-archive** — collapsed "Archived" section in sidebar
7. **Notification badge** — unread count in sidebar UI
8. **Uploads** — actual S3 presigned URL generation
9. **Tests** — for all new features

---

## Changes

### 1. Chat Context Enhancements

Add to `lib/pingbase/chat.ex`:

- `send_message/3` — creates message, parses mentions, creates notifications, broadcasts to PubSub
- `parse_mentions/1` — regex to find `@username` or `@display_name` in content
- `broadcast_message/1` — `Phoenix.PubSub.broadcast` to `"room:{room_id}"`
- `broadcast_typing/2` — ephemeral broadcast for typing indicators
- `list_thread_messages/1` — already exists, verify it works
- `update_last_read/2` — update `room_membership.last_read_message_id`

### 2. Notifications Context Enhancements

Add to `lib/pingbase/notifications.ex`:

- `notify_mention/2` — create notification for mention
- `notify_thread_reply/2` — create notification for thread reply

### 3. RoomLive Show (`lib/pingbase_web/live/room_live/show.ex`)

Rewrite to include:

- **PubSub subscription** on mount → `handle_info` for new messages
- **Stream messages** instead of plain list → `phx-stream` for efficient DOM updates
- **Infinite scroll** → `phx-viewport-top` with `before_id` pagination
- **Thread sidebar** → conditional right panel showing thread replies
- **Typing indicators** → `phx-window-keyup` debounced broadcast
- **Message sending** → `create_message` + broadcast
- **Reactions** → `handle_event` for add/remove
- **Message editing** → `handle_event` for edit
- **Notification badge** → show unread count per room

### 4. WorkspaceLive Show (`lib/pingbase_web/live/workspace_live/show.ex`)

Enhance sidebar:

- **Collapsed sections** — Active channels, Archived channels, DMs
- **Notification badges** — per-room unread count
- **Auto-archive** — rooms with `is_archived: true` go to collapsed section
- **Room creation** — button to create new channel

### 5. Uploads

Fix `lib/pingbase/uploads.ex`:

- Use actual S3 presigned URL generation (simplified but functional)
- Support ExAws if available, fallback to manual presigned URL

### 6. Components

Create `lib/pingbase_web/components/chat_components.ex`:

- `<.message />` — reusable message component
- `<.reaction_bar />` — reactions display
- `<.thread_panel />` — thread sidebar component
- `<.typing_indicator />` — typing dots

### 7. Tests

- `test/pingbase/chat_test.exs` — mention parsing, notifications
- `test/pingbase/notifications_test.exs` — notification creation
- `test/pingbase_web/live/room_live_test.exs` — LiveView feature tests
- `test/pingbase/uploads_test.exs` — presigned URL generation

---

## Implementation Order

1. Chat context enhancements (send_message, mentions, broadcasts)
2. Notifications context enhancements
3. RoomLive rewrite (streams, real-time, threads, typing)
4. WorkspaceLive sidebar enhancements (archive, badges)
5. Chat components extraction
6. Uploads fix
7. Tests
8. Run `mix test` and verify

## Verification

- `mix test` passes
- `mix phx.server` — verify real-time chat works
- Docker logs clean

---

## Notes

- Keep changes minimal — Phase 2 is about wiring up, not adding new schemas
- All context functions remain pure and API-agnostic
- PubSub topics: `"room:{room_id}"` for messages, `"room:{room_id}:typing"` for typing
- Presence topics: `"room:{room_id}:presence"` for online status
- Streams use `dom_id: "messages-" <> message.id` for stable IDs
